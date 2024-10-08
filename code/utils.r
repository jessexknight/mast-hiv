# -----------------------------------------------------------------------------
# options + aliases

cli.arg = function(name,default=NA){
  args = strsplit(commandArgs(trailingOnly=TRUE),'=')
  x = args[[match(name,sapply(args,`[`,1))]][2]
  if (length(x)){ x = type.convert(x,as.is=TRUE) }
  else          { x = default }
}

options(
  stringsAsFactors=FALSE,
  showNCalls=500,
  width=200,
  warn=1)

len = length
lens = lengths
str = paste0

# -----------------------------------------------------------------------------
# files + i/o

# proj.root: full path to parent of /code.r/fio.r
proj.root = strsplit(file.path(getwd(),''),file.path('','code',''))[[1]][1]

root.path = function(...,create=FALSE){
  # e.g. root.path('abc','123') returns proj.root/abc/123
  path = file.path(proj.root,...)
  if (create & !dir.exists(dirname(path))){
    dir.create(dirname(path),recursive=TRUE) }
  return(path)
}

.verb = cli.arg('.verb',4)

status = function(lvl,...){
  if (lvl > .verb){ return() }
  pre = list(c(rep('-',80),'\n'),'',' > ','')[[lvl]]
  end = list('\n','\n','\n','')[[lvl]]
  cat(pre,...,end,sep='')
}

# -----------------------------------------------------------------------------
# vector tools

sum1 = function(x){
  x/sum(x)
}

na.to.num = function(x,num=0){
  # replace NA in x with num
  x[is.na(x)] = num
  return(x)
}

int.cut = function(x,low){
  # cut with simplified labels (assume integers)
  # e.g. int.cut(1:6,c(1,2,3,5)) -> c('1','2','3-4','3-4','5+','5+')
  high = c(low[2:len(low)]-1,Inf)
  labels = gsub('-Inf','+',ifelse(low==high,low,str(low,'-',high)))
  x.cut = cut(x,breaks=c(low,Inf),labels=labels,right=FALSE)
}

breaks = function(x,n=30){
  b = hist(x,breaks=min(n,ulen(x)),plot=FALSE)$breaks
}

ulen = function(x){
  # e.g. ulen(c(1,1,1,2,3)) -> 3
  len(unique(x))
}

even.sum = function(x){
  if (sum(x) %% 2){
    i = which.max(x)
    x[i] = x[i] - 1
  }
  return(x)
}

reppend = function(x,xa,n){
  append(x,rep.int(xa,n))
}

last = function(x){
  # return the last element in x or NA if len(x) == 0
  if (len(x)){ x[len(x)] } else { NA }
}

# -----------------------------------------------------------------------------
# list tools

ulist = function(x=list(),xu=list(),...){
  # e.g. ulist(list(a=1,b=2),xu=list(a=3),b=4) -> list(a=3,b=4)
  x = c(x,xu,list(...))
  x[!duplicated(names(x),fromLast=TRUE)]
}

flist = function(x){
  # flatten list(list(a=1),list(b=2)) -> list(a=1,b=2)
  do.call(c,unname(x))
}

filter.names = function(x,re,b=TRUE){
  # e.g. filter.names(list(a1=0,a2=0,ba=0),'^a') -> c('a1','a2')
  names(x)[grepl(re,names(x),perl=TRUE)==b]
}

list.str = function(x,def=' = ',join='\n',sig=Inf){
  # e.g. list.str(list(a=1,b=2)) -> 'a = 1\nb = 2'
  f = function(x){ ifelse(is.numeric(x),signif(x,sig),x) }
  paste(names(x),lapply(x,f),sep=def,collapse=join)
}

df.compare = function(x,y,v=NULL,cast=as.numeric){
  # check if x[v] == y[v] (for debug)
  if (is.null(v)){ v = intersect(names(x),names(y)) }
  eq = all.equal(lapply(x[v],cast),lapply(y[v],cast))
  status(3,'df.compare @ ',paste(v,collapse=','),': ',
    ifelse(eq==TRUE,'OK',paste('\n',eq)))
}

# -----------------------------------------------------------------------------
# *apply

.cores = cli.arg('.cores',7)

par.lapply = function(...,.par=TRUE){
  if (.par && len(list(...)[[1]]) > 1){
    parallel::mclapply(...,mc.cores=.cores) }
  else {
    lapply(...)
  }
}

par.mapply = function(...){
  parallel::mcmapply(...,mc.cores=.cores,SIMPLIFY=FALSE)
}

rbind.lapply = function(...){
  do.call(rbind,c(par.lapply(...),list(make.row.names=FALSE)))
}

wapply = function(...){
  mapply(...,SIMPLIFY=FALSE)
}

grid.apply = function(x,fun,args,...,.par=TRUE){
  # e.g. grid.lapply(list(a=1:2,b=3:4),fun,c=5) runs:
  # fun(a=1,b=3,c=5), fun(a=2,b=3,c=5), fun(a=1,b=4,c=5), fun(a=2,b=4,c=5)
  xg = expand.grid(x,stringsAsFactors=FALSE)
  grid.args = lapply(1:nrow(xg),function(i){ ulist(as.list(xg[i,]),args,...) })
  par.lapply(grid.args,do.call,what=fun,.par=.par)
}

def.args = function(f,...){
  args = list(...)
  f.pre = function(...){ do.call(f,c(args,list(...))) }
}

maggregate = function(...){
  # clean-up multiple returns from FUN
  x = do.call(data.frame,aggregate(...))
}

# -----------------------------------------------------------------------------
# stats

fit.beta = function(qs,ps=c(.025,.975)){
  efun = function(par){ e = sum(abs(ps-pbeta(qs,par[1],par[2]))) }
  optim(c(1,1),efun,method='L-BFGS-B',lower=0)$par
}

copula = function(n,covs,qfuns,...){
  # joint sample from qfuns (args in ...) with correlation (covs)
  # e.g. copula(100,0.5,list(a=qexp,b=qunif),a=list(rate=1),b=list(min=0,max=1))
  #      draws 100 samples from rexp & runif with 50% corrleation
  # final correlations are not exact due to quantile transformations
  d = len(qfuns)
  sigma = matrix(0,d,d)
  sigma[lower.tri(sigma)] = covs
  sigma = sigma + t(sigma) + diag(d)
  ms = mvtnorm::rmvnorm(n,sigma=sigma) # sample from mvn
  ps = as.list(data.frame(pnorm(ms))) # normal cdf transform
  xs = mapply(function(qfun,p,args){ # for each qfun, p vector, args
    do.call(qfun,ulist(args,p=p)) # target distr quantile transform
  },qfuns,ps,list(...))
}
