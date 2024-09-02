
# =============================================================================
# config

.p.vars = c('case','seed')
.i.vars = c(
  'i',
  'z.born','age.act',
  'vio.Ri',
  'dep_o.Ri','dep_x.Ri',
  'haz_o.Ri','haz_x.Ri',
  'ptr_o.Ri','ptr_x.Ri','ptr.max')

# =============================================================================
# survey funs

srv.apply = function(Ms,t,srvs=c(srv.base),p.vars=NULL,i.vars=NULL){
  # apply 1+ surveys (srvs) to sim outputs (Ms) at time (t)
  status(3,'srv.apply: ',len(Ms))
  if (missing(t)){ t = Ms[[1]]$P$tf }
  Ps = lapply(Ms,`[[`,'P')
  Es = lapply(Ms,`[[`,'E')
  Qs = lapply(Ms,srv.init,t=t,p.vars=p.vars,i.vars=i.vars)
  for (srv in srvs){
    Qs = par.mapply(srv,Ps,Qs,Es,t) }
  Q = do.call(rbind,Qs)
}

srv.init = function(M,t,p.vars,i.vars){
  p.vars = unique(c(.p.vars,p.vars))
  i.vars = unique(c(.i.vars,i.vars))
  Q = cbind(M$P[p.vars],t=t,M$I[i.vars]) # init Q ~= I
  # Q = srv.base(M$P,Q,M$E,t); x = intersect(names(M$I),names(Q))
  # print(all.equal(M$I[x],Q[x])) # DEBUG
}

srv.base = function(P,Q,E,t,fmt='%s'){
  E = clip.evts(E,t=t)
  Q$age      = (t-Q$t.born)/P$t1y
  Q$sex.act  = Q$age > Q$age.act
  Q$vio.nt   = sapply(E$vio,len)
  Q$vio.tr   = sapply(E$vio,last)
  Q$dep.now  = sapply(E$dep_o,len) > sapply(E$dep_x,len)
  Q$dep.past = sapply(E$dep_o,len) > 0
  Q$dep.to   = sapply(E$dep_o,last)
  Q$dep.dur  = ifelse(Q$dep.now,t-Q$dep.to,NA)
  Q$haz.now  = sapply(E$haz_o,len) > sapply(E$haz_x,len)
  Q$haz.past = sapply(E$haz_o,len) > 0
  Q$haz.zo   = sapply(E$haz_o,last)
  Q$haz.dur  = ifelse(Q$haz.now,t-Q$haz.to,NA)
  Q$ptr.nt   = sapply(E$ptr_o,len)
  Q$ptr.nw   = Q$ptr.nt - sapply(E$ptr_x,len)
  names(Q) = sprintf(fmt,names(Q)) # format names for conflicts
  return(Q)
}

# -----------------------------------------------------------------------------

srv.val.RR = function(P,Q,E,t){
  E = clip.evts(E,t=t)
  Q = srv.base(P,Q,E,t)
  Q$age.10 = floor(Q$age/10)*10
  # events in past 1 year
  Q$vio.n1y   = sapply(E$vio,  num.dt,t,P$t1y)
  Q$vio.a1y   = sapply(E$vio,  any.dt,t,P$t1y)
  Q$dep_o.a1y = sapply(E$dep_o,any.dt,t,P$t1y)
  Q$dep_x.a1y = sapply(E$dep_x,any.dt,t,P$t1y)
  Q$haz_o.a1y = sapply(E$haz_o,any.dt,t,P$t1y)
  Q$haz_x.a1y = sapply(E$haz_x,any.dt,t,P$t1y)
  Q$ptr_o.n1y = sapply(E$ptr_o,num.dt,t,P$t1y)
  Q$ptr_x.n1y = sapply(E$ptr_x,num.dt,t,P$t1y)
  # states 1 year prior
  Q = cbind(Q,srv.base(P,Q,E,t-P$t1y,fmt='p1y.%s'))
  Q$p1y.dep.dur.c = int.cut(Q$p1y.dep.dur/P$t1y,c(0,1,5))
  Q$p1y.haz.dur.c = int.cut(Q$p1y.haz.dur/P$t1y,c(0,1,5))
  Q$p1y.vio.nt.c  = int.cut(Q$p1y.vio.nt,c(0,3,30))
  # events in past 3 months
  Q$vio.n3m   = sapply(E$vio,  num.dt,t,P$t3m)
  Q$vio.a3m   = sapply(E$vio,  any.dt,t,P$t3m)
  Q$dep_o.a3m = sapply(E$dep_o,any.dt,t,P$t3m)
  Q$dep_x.a3m = sapply(E$dep_x,any.dt,t,P$t3m)
  Q$haz_o.a3m = sapply(E$haz_o,any.dt,t,P$t3m)
  Q$haz_x.a3m = sapply(E$haz_x,any.dt,t,P$t3m)
  Q$ptr_o.n3m = sapply(E$ptr_o,num.dt,t,P$t3m)
  Q$ptr_x.n3m = sapply(E$ptr_x,num.dt,t,P$t3m)
  # states 3 months prior
  Q = cbind(Q,srv.base(P,Q,E,t-P$t3m,fmt='p3m.%s'))
  Q$p3m.dep.dur.c = int.cut(Q$p3m.dep.dur/P$t1y,c(0,1,5))
  Q$p3m.haz.dur.c = int.cut(Q$p3m.haz.dur/P$t1y,c(0,1,5))
  Q$p3m.vio.nt.c  = int.cut(Q$p3m.vio.nt,c(0,3,30))
  return(Q)
}

# -----------------------------------------------------------------------------

dt.data = function(P,Q,E,q.vars=NULL){
  # TODO: tmin / tmax ?
  # TODO: integrate in srv.* framework
  # TODO: not all evts
  Y = rbind.lapply(1:nrow(Q),function(i){
    z0 = Q$z.born[i] + P$z1y * amin
    zf = Q$z.born[i] + P$z1y * amax
    zi = sort(do.call(c,lapply(E[evts],`[[`,i))) # all event times
    ei = gsub('\\d','',names(zi))                # all event names
    Yi = cbind(
      lapply(Q[q.vars],`[`,i),
      data.frame(
        e  = c(ei,''), # event name
        dt = P$dtz * diff(c(z0,zi,zf)), # time in this state
        vio.nt  = c(0,cumsum(ei=='vio')),
        dep.now = c(0,cumsum(ei=='dep_o')-cumsum(ei=='dep_x')),
        haz.now = c(0,cumsum(ei=='haz_o')-cumsum(ei=='haz_x')),
        ptr.nw  = c(0,cumsum(ei=='ptr_o')-cumsum(ei=='ptr_x')),
        row.names = NULL))
  },.par=FALSE)
}

inc.rate = function(Y,e,strat=NULL){
  # TODO: integrate in srv.* framework
  # TODO: rownames
  Y = subset(Y,e != '')
  Y = switch(e,
    vio = Y,
    dep_o = subset(Y,dep.now==0),
    dep_x = subset(Y,dep.now==1),
    haz_o = subset(Y,haz.now==0),
    haz_x = subset(Y,haz.now==1),
    ptr_o = subset(Y,ptr.nw < ptr.max),
    ptr_x = subset(Y,ptr.nw > 0))
  y.split = split(1:nrow(Y),cbind(Y[strat],.=''))
  R = rbind.lapply(y.split,function(y){
    cbind(Y[y[1],strat,drop=FALSE],
      event=e,
      rate=sum(Y$e[y]==e)/sum(Y$dt[y]))
  })
}

# =============================================================================
# question / event funs

clip.evts = function(E,t){ E = lapply(E,lapply,clip.tes,t=t) }

clip.tes = function(tes,t){ tes[tes <= t] }

num.dt = function(tes,t,dt){ n = sum(tes <= t & tes > t-dt) }

any.dt = function(tes,t,dt){ b = num.dt(tes,t,dt) > 0 }
