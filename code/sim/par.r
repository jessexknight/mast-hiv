
# =============================================================================
# pars

get.pars = function(seed=0,...,dtz=7,case='base',null=NULL,save=NULL){
  P = list(case=case,seed=seed,id=sprintf('%6d',seed))
  P = dt.pars(P,dtz)
  P$n.pop = 1000
  P$n.dur = 1+1
  # base rates
  P$vio.Ri.m    = 1/P$t1y    # (mean) base rate: violence
  P$dep_o.Ri.m  = 0.01/P$t1y # (mean) base rate: depression begin
  P$dep_x.Ri.m  = 1.00/P$t1y # (mean) base rate: depression end
  P$haz_o.Ri.m  = 0.01/P$t1y # (mean) base rate: hazdrink begin
  P$haz_x.Ri.m  = 1.00/P$t1y # (mean) base rate: hazdrink end
  P$ptr_o.Ri.m  = 1/30       # (mean) base rate: partner begin
  P$ptr_x.Ri.m  = 1/30       # (mean) base rate: partner end
  P$sex.Ri.95   = c(.1,.5)   # (95% CI) base rate: sex within ptr
  P$cdm.Pi.95   = c(.2,.8)   # (95% CI) prob: condom use
  # base rate covariance, shapes, etc.
  P$ptr.max.m   = 1.50      # (mean) max num partners
  P$dep.cov     = -.9       # approx covariance among dep_o,dep_x
  P$haz.cov     = -.9       # approx covariance among haz_o,haz_x
  P$ptr.cov     = +.9       # approx covariance among ptr_o,ptr_x,ptr.max
  P$ptr.Ri.shape = 3        # (gamma shape): ptr_o,ptr_x
  P$all.Ri.shape = 1        # (gamma shape): all other base rates
  # RR: age -> *
  P$aRR.vio.ages   = c(amin,amax) # (age points) RR: age -> vio
  P$aRR.vio.RRs    = c(1.00,1.00) # (RR  points) RR: age -> vio
  P$aRR.dep_o.ages = c(amin,amax) # (age points) RR: age -> dep begin
  P$aRR.dep_o.RRs  = c(1.00,1.00) # (RR  points) RR: age -> dep begin
  P$aRR.haz_o.ages = c(amin,amax) # (age points) RR: age -> haz begin
  P$aRR.haz_o.RRs  = c(1.00,1.00) # (RR  points) RR: age -> haz begin
  P$aRR.ptr_o.ages = c(amin,amax) # (age points) RR: age -> ptr begin
  P$aRR.ptr_o.RRs  = c(1.00,1.00) # (RR  points) RR: age -> ptr begin
  # RR: * -> dep begin
  P$ RR.dep_o.dep_p  = 3     # RR: dep past -> dep begin
  P$iRR.dep_o.vio_zr = 2     # (initial RR) transient RR: vio -> dep begin
  P$tsc.dep_o.vio_zr = 30    # (time scale) transient RR: vio -> dep begin
  P$mRR.dep_o.vio_nt = 2     # (max RR)    cumulative RR: vio -> dep begin
  P$nsc.dep_o.vio_nt = 10    # (n scale)   cumulative RR: vio -> dep begin
  # RR: * -> dep end
  P$dsc.dep_x.dep_u  = P$t1y # (dur scale)  duration RR: dep dur -> dep end
  P$iRR.dep_x.vio_zr = 1/2   # (initial RR) transient RR: vio -> dep end
  P$tsc.dep_x.vio_zr = 30    # (time scale) transient RR: vio -> dep end
  # RR: * -> haz begin
  P$ RR.haz_o.haz_p  = 3     # RR: haz past -> haz begin
  P$ RR.haz_o.dep_w  = 3     # RR: dep now -> haz begin
  P$iRR.haz_o.vio_zr = 2     # (initial RR) transient RR: vio -> haz begin
  P$tsc.haz_o.vio_zr = 30    # (time scale) transient RR: vio -> haz begin
  P$mRR.haz_o.vio_nt = 2     # (max RR)    cumulative RR: vio -> haz begin
  P$nsc.haz_o.vio_nt = 10    # (n scale)   cumulative RR: vio -> haz begin
  # RR: * -> haz end
  P$ RR.haz_x.dep_w  = 1/3   # RR: dep now -> haz end
  P$dsc.haz_x.haz_u  = P$t1y # (dur scale)  duration RR: haz dur -> haz end
  P$iRR.haz_x.vio_zr = 1/2   # (initial RR) transient RR: vio -> haz end
  P$tsc.haz_x.vio_zr = 30    # (time scale) transient RR: vio -> haz end
  # RR: * -> ptr begin
  P$ RR.ptr_o.dep_w  = 1/2   # RR: dep now -> ptr begin
  P$ RR.ptr_o.haz_w  = 2     # RR: haz now -> ptr begin
  P$iRR.ptr_o.vio_zr = 1/2   # (initial RR) transient RR: vio -> ptr begin
  P$tsc.ptr_o.vio_zr = 30    # (time scale) transient RR: vio -> ptr begin
  P$mRR.ptr_o.vio_nt = 1/2   # (max RR)    cumulative RR: vio -> ptr begin
  P$nsc.ptr_o.vio_nt = 10    # (n scale)   cumulative RR: vio -> ptr begin
  # RR: * -> ptr end
  P$ RR.ptr_x.dep_w  = 2     # RR: dep now -> ptr end
  P$ RR.ptr_x.haz_w  = 2     # RR: haz now -> ptr end
  # overwrite & add conditional
  P = null.pars(P,null,save)
  P = ulist(P,...)
  P = cond.pars(P)
}

dt.pars = function(P,dtz){
  P$dtz  = dtz              # days in 1 timestep
  P$z3m  = round(364/dtz/4) # timesteps in 3 months
  P$z6m  = 2 * P$z3m        # timesteps in 6 months
  P$z1y  = 4 * P$z3m        # timesteps in 1 year
  P$t1y  = dtz * P$z1y      # days in 1 year
  P$t3m  = dtz * P$z3m      # days in 3 months
  P$t6m  = dtz * P$z6m      # days in 6 months
  return(P)
}

cond.pars = function(P){
  P$zf    = P$n.dur*adur*P$z1y # final timestep
  P$tf    = P$zf * P$dtz       # final time (days)
  P$n.tot = P$n.pop * (1+P$n.dur) # total inds needed
  P$sex.Ri.shapes = fit.beta(P$sex.Ri.95) # (shape1,shape2): sex rate
  P$cdm.Pi.shapes = fit.beta(P$cdm.Pi.95) # (shape1,shape2): condom prob
  # RR: age
  P$aRR.vio   = def.RR.age(P$aRR.vio.ages,P$aRR.vio.RRs) # RR: age -> vio
  P$aRR.dep_o = def.RR.age(P$aRR.dep_o.ages,P$aRR.dep_o.RRs) # RR: age -> dep begin
  P$aRR.haz_o = def.RR.age(P$aRR.haz_o.ages,P$aRR.haz_o.RRs) # RR: age -> haz begin
  P$aRR.ptr_o = def.RR.age(P$aRR.ptr_o.ages,P$aRR.ptr_o.RRs) # RR: age -> ptr begin
  # tRR: vio
  def.tRR = def.tRR.exp
  P$tRRu.dep_o.vio_zr = def.tRR(P$iRR.dep_o.vio_zr,P$tsc.dep_o.vio_zr,P$dtz) - 1 # tRR-1: vio -> dep begin
  P$tRRu.dep_x.vio_zr = def.tRR(P$iRR.dep_x.vio_zr,P$tsc.dep_x.vio_zr,P$dtz) - 1 # tRR-1: vio -> dep end
  P$tRRu.haz_o.vio_zr = def.tRR(P$iRR.haz_o.vio_zr,P$tsc.haz_o.vio_zr,P$dtz) - 1 # tRR-1: vio -> haz begin
  P$tRRu.haz_x.vio_zr = def.tRR(P$iRR.haz_x.vio_zr,P$tsc.haz_x.vio_zr,P$dtz) - 1 # tRR-1: vio -> haz end
  P$tRRu.ptr_o.vio_zr = def.tRR(P$iRR.ptr_o.vio_zr,P$tsc.ptr_o.vio_zr,P$dtz) - 1 # tRR-1: vio -> ptr begin
  # nRR: vio
  def.nRR = def.nRR.exp
  P$nRR.dep_o.vio_nt = def.nRR(P$mRR.dep_o.vio_nt,P$nsc.dep_o.vio_nt,P$z1y) # nRR: vio -> dep begin
  P$nRR.haz_o.vio_nt = def.nRR(P$mRR.haz_o.vio_nt,P$nsc.haz_o.vio_nt,P$z1y) # nRR: vio -> haz begin
  P$nRR.ptr_o.vio_nt = def.nRR(P$mRR.ptr_o.vio_nt,P$nsc.ptr_o.vio_nt,P$z1y) # nRR: vio -> ptr begin
  # dRR: durs
  P$dRRu.dep_x.dep_u = def.dRR.exp(P$dsc.dep_x.dep_u,P$dtz,P$z1y) - 1 # dRR-1: dep dur -> dep end
  P$dRRu.haz_x.haz_u = def.dRR.exp(P$dsc.haz_x.haz_u,P$dtz,P$z1y) - 1 # dRR-1: dep dur -> dep end
  # pre-compute RR-1 for all RR.*
  for (x in filter.names(P,'^RR')){
    P[[gsub('RR','RRu',x)]] = P[[x]] - 1
  }
  # for (x in filter.names(P,'^(t|n|d)RR')){ plot(grepl('RRu',x)+P[[x]]); title(x) } # DEBUG
  return(P)
}

null.pars = function(P,null,save){
  P.save = P[save] # save exempt
  map = flist(null.sets[null]) # merge regex list
  for (re in names(map)){ # for each regex
    for (x in filter.names(P,re)){ # for each matching par
      P[[x]] = map[[re]] }} # overwrite
  P = ulist(P,P.save) # restore saved
}

null.sets = list(
  Ri  = list('Ri\\.m$'=0),
  RR  = list('^RR\\.'=1),
  tRR = list('^iRR\\.'=1,'^tsc\\.'=1e-12),
  nRR = list('^mRR\\.'=1,'^nsc\\.'=Inf),
  dRR = list('^dsc\\.'=Inf))
null.sets$xRR = flist(null.sets[2:5])
null.sets$all = flist(null.sets)

# =============================================================================
# effect funs

def.RR.age = function(age,RR,eps=.001){
  n = len(RR)
  RR  = c(RR[1],RR,RR[n])
  age = c(age[1]-eps,age,age[n]+eps)
  RR.age = splinefun(age,RR,method='monoH.FC')(seq(amin,amax))
}

def.nRR.exp = function(mRR,nsc,z1y){
  n = 0:(z1y*adur) # nmax = all active timesteps
  nRR = 1 + (mRR-1) * (1-exp(-n/nsc))
}

def.nRR.rect = function(mRR,nsc,z1y){
  nmax = z1y*adur # nmax = all active timesteps
  nRR = c(rep(1,nsc),rep(mRR,nmax-nsc))
}

def.dRR.exp = function(tsc,dtz,z1y){
  z = 1:(z1y*adur) # dmax = all active timesteps
  dRR = exp(-z*dtz/tsc)
}

def.tRR.rect = function(iRR,tsc,dtz){
  ntz = tsc/dtz
  tRR = 1 + (iRR-1) * c(rep(1,floor(ntz)),ntz-floor(ntz))
}

def.tRR.exp = function(iRR,tsc,dtz,eps=.001){
  z = 1:ceiling(qexp(p=1-eps,rate=1/tsc)/dtz) # ensure we cover most AUC
  tRR = 1 + (iRR-1) * exp(-z*dtz/tsc)
}

map.tRR = function(tRRu,ze,z){
  # lookup & sum RR kernel for now (z) given prior events (ze)
  RR = 1 + na.to.num(tRRu[z+1-ze])
}
