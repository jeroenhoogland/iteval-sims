library(ggplot2)
library(patchwork)
library(stringr)
library(xtable)

# folder where the simulation results are stored
dir <- "replicate/"
files <- list.files(dir)
files <- grep("ite*", files, value = TRUE)
nsim <- length(files)
nss <- 3

numextract <- function(string){
  as.numeric(str_extract(string, "\\-*\\d+"))
}

files <- files[order(numextract(files))]

sr <- plyr::llply(paste0(dir, files), function(x){
  load(x)
  return(list=(r=results))}, .progress = "text")

names(sr) <- paste0("sim", numextract(files))

sample.sizes <- c(500, 750, 1000)

# List structure: sr, nsim, sample.size, measure

names(sr$sim1$n500)

######################
## Discrimination ####
######################

# Monte Carlo error for the individual measures
discr.list <- c("apparent.discr", "ext1.app.discr", "ext2.app.discr",
                "boot0.632.discr", "boot.opt.discr", "ext1.total.discr",
                "ext2.total.discr")

plot.discr <- function(sr, m, columns, print.msd=TRUE, ylim=NULL, ...){

  ellipsis <- list(...)

  plot.data <- array(as.numeric(sapply(sr, function(x) sapply(x, function(xx) unlist(xx[m])))),
                     dim=c(5, nss, nsim))

  msd <- cbind(
    apply(cbind(t(plot.data[ ,1, ]), t(plot.data[ ,2, ]), t(plot.data[ ,3, ]))[,columns],
          2, mean),
    apply(cbind(t(plot.data[ ,1, ]), t(plot.data[ ,2, ]), t(plot.data[ ,3, ]))[,columns],
          2, sd))

  msd <- data.frame("cstat"=msd[,1], "sd"=msd[,2],
                    upp=msd[,1]+1*msd[,2], low=msd[,1]-1*msd[,2],
                    "statistic"=factor(rep(c("cforbendelta", "cforbeny0", "mbcb", "cforbennew", "theta_d"), 3),
                                       levels = c("cforbendelta", "cforbeny0", "mbcb", "cforbennew", "theta_d")),
                    "sample.size"=factor(rep(sample.sizes, each=5)))

  #!#! order switched
  msd$statistic <- factor(msd$statistic, levels=levels(msd$statistic)[c(1,4,2,3,5)])

  if(print.msd){
    print(msd)
  }

  if(!is.null(ellipsis$ylab)) ylab <- ellipsis$ylab else ylab <- ""
  if(!is.null(ellipsis$title)) title <- ellipsis$title else title <- ""

  ggplot(msd, aes(x=statistic, y=cstat, group=sample.size, colour=sample.size)) +
    geom_point(position=position_dodge(width=0.7)) +
    geom_errorbar(aes(x=statistic, ymax=upp, ymin=low), na.rm=TRUE, position=position_dodge(width=0.7)) +
    theme_bw() + ylim(ylim) +
    guides(x =  guide_axis(angle = 45)) +
    labs(x = "",y=ylab, title=title, col="Sample size") +
    scale_x_discrete(labels = c(expression("cben-"*hat(delta)),
                                expression("cben"[ppte]),
                                expression("cben-"*hat(y)[0]),
                                "mbcm",
                                bquote(theta["d"]))) +

    theme(text = element_text(size=14),
          axis.text.x=element_text(size=rel(1.3)),
          axis.text.y=element_text(size=rel(1.3)))
}

# Create a 3 + 2 version
# make sure the ext1.app.discr results for cforbendelta and cforbennew are available in ext1.total.discr
for(i in 1:nsim){
  for(j in 1:length(sample.sizes)){
    sr[[i]][[j]]$ext1.total.discr$cforbenefit <- sr[[i]][[j]]$ext1.app.discr$cforbenefit
    sr[[i]][[j]]$ext1.total.discr$cforbenefit.new <- sr[[i]][[j]]$ext1.app.discr$cforbenefit.new

    sr[[i]][[j]]$ext2.total.discr$cforbenefit <- sr[[i]][[j]]$ext2.app.discr$cforbenefit
    sr[[i]][[j]]$ext2.total.discr$cforbenefit.new <- sr[[i]][[j]]$ext2.app.discr$cforbenefit.new
  }
}
columns <- 1:15
ylim <- c(0.475, 0.675)
layout <- "
AAABBBCCCC
#DDDFFF###
"
p1 <- plot.discr(sr, "apparent.discr", columns, ylim=ylim, title="Apparent (DGM1)", ylab="C-statistic")
p4 <- plot.discr(sr, "boot0.632.discr", columns, ylim=ylim, title="Bootstrap\n0.632+")
p5 <- plot.discr(sr, "boot.opt.discr", columns, ylim=ylim, title="Bootstrap\nOptimism corrected")
p6 <- plot.discr(sr, "ext1.total.discr", columns, ylim=ylim, title="External data DGM1*", ylab="C-statistic")
p7 <- plot.discr(sr, "ext2.total.discr", columns, ylim=ylim, title="External data DGM2*")
pl <- p1 + p4 + p5 + p6 + p7 +
  plot_layout(guides = "collect", design=layout) &
  theme(legend.position = "bottom")
pl

## plot versus estimand
columns <- 1:12 # 4 methods * 3 sample sizes
plot.discr.estimand <- function(sr, m, columns, print.msd=TRUE, ylim=NULL, ...){

  ellipsis <- list(...)

  plot.data <- array(as.numeric(sapply(sr, function(x) sapply(x, function(xx){
    zz <- unlist(xx[m])
    zz[1:4] - zz[5]
  }))), dim=c(4, nss, nsim))

  msd <- cbind(
    apply(cbind(t(plot.data[ ,1, ]), t(plot.data[ ,2, ]), t(plot.data[ ,3, ]))[,columns],
          2, mean),
    apply(cbind(t(plot.data[ ,1, ]), t(plot.data[ ,2, ]), t(plot.data[ ,3, ]))[,columns],
          2, sd))

  msd <- data.frame("cstat"=msd[,1], "sd"=msd[,2],
                    upp=msd[,1]+1*msd[,2], low=msd[,1]-1*msd[,2],
                    "statistic"=factor(rep(c("cforbendelta", "cforbeny0", "mbcb", "cforbennew"), 3),
                                       levels = c("cforbendelta", "cforbeny0", "mbcb", "cforbennew")),
                    "sample.size"=factor(rep(sample.sizes, each=4)))

  msd$statistic <- factor(msd$statistic, levels=levels(msd$statistic)[c(1,4,2,3)])

  if(print.msd){
    print(msd)
  }

  if(!is.null(ellipsis$ylab)) ylab <- ellipsis$ylab else ylab <- ""
  if(!is.null(ellipsis$title)) title <- ellipsis$title else title <- ""

  ggplot(msd, aes(x=statistic, y=cstat, group=sample.size, colour=sample.size)) +
    geom_hline(yintercept=0, linetype="dashed",
               color = "grey", size=1) +
    geom_point(position=position_dodge(width=0.7)) +
    geom_errorbar(aes(x=statistic, ymax=upp, ymin=low), na.rm=TRUE, position=position_dodge(width=0.7)) +
    theme_bw() + ylim(ylim) +
    guides(x =  guide_axis(angle = 45)) +
    labs(x = "",y=ylab, title=title, col="Sample size") +
    scale_x_discrete(labels = c(expression("cben-"*hat(delta)),
                                expression("cben"[ppte]),
                                expression("cben-"*hat(y)[0]),
                                "mbcm")) +
    theme(text = element_text(size=14),
          axis.text.x=element_text(size=rel(1.3)),
          axis.text.y=element_text(size=rel(1.3)))
}
columns <- 1:12
ylim <- c(-0.05, 0.075)
layout <- "
AAABBBCCCC
#DDD#FFF##
"
p1 <- plot.discr.estimand(sr, "apparent.discr", columns, ylim=ylim, title="Apparent (DGM1)", ylab="Deviation from estimand")
p4 <- plot.discr.estimand(sr, "boot0.632.discr", columns, ylim=ylim, title="Bootstrap\n0.632+")
p5 <- plot.discr.estimand(sr, "boot.opt.discr", columns, ylim=ylim, title="Bootstrap\nOptimism corrected")
p6 <- plot.discr.estimand(sr, "ext1.total.discr", columns, ylim=ylim, title="External data DGM1",ylab="Deviation from estimand")
p7 <- plot.discr.estimand(sr, "ext2.total.discr", columns, ylim=ylim, title="External data DGM2")
pl <- p1 + p4 + p5 + p6 + p7 +
  plot_layout(guides = "collect", design=layout) &
  theme(legend.position = "bottom")
pl

# rmse
# pl gives monte carlo estimate as a function of the number of sims
rmse.discr <- function(sr, m,
                       ref="sample", # ref=c("sample", "population"),
                       pl=FALSE, digits=NULL){
  rmse.data <- array(as.numeric(sapply(sr, function(x) sapply(x, function(xx) unlist(xx[m])))),
                     dim=c(5, nss, nsim))
  if(ref=="sample"){
    main <- c("cbendelta", "cbeny0hat", "mbcb", "cbennew")
    err <- lapply(1:4, function(x) rmse.data[x,,] - rmse.data[5,,])
    out <- t(sapply(err, function(x) apply(x, 1, function(xx) sqrt(mean(xx^2)))))
    if(pl){
      sapply(1:3, function(p)
        if(sum(is.na(err[[p]])) == 0){
          matplot(apply(err[[p]], 1, function(x) sqrt(cumsum(x^2) / (1:length(x)))), type="l", main=paste(m, main[p]))
        } else {
          plot.new()
        })
    }
  }

  colnames(out) <- paste0("n", sample.sizes)
  rownames(out) <- c("cbendelta", "cbeny0hat", "mbcb", "cbennew")
  if(!is.null(digits)) out <- round(out, digits)
  return(out)
}
library(xtable)
xtable(t(sapply(discr.list, function(m){
  xx <- t(rmse.discr(sr, m, ref="sample", pl=FALSE, digits=3))
  c(paste(xx[1], xx[2], xx[3], sep=","), # cben
    paste(xx[10], xx[11], xx[12], sep=","), # cben new
    paste(xx[4], xx[5], xx[6], sep=","), # cben y0hat
    paste(xx[7], xx[8], xx[9], sep=",")) # mbcb
})))

###################
## Calibration ####
###################

## Plot int and slope in same plot
library(DescTools)
plot.cal <- function(sr, m, columns, print.msd=TRUE, ylim=NULL, ...){

  ellipsis <- list(...)

  empirical.both <- ifelse(!is.null(sr$sim1$n500[[m]]$empirical.both), TRUE, FALSE)
  true.both <- ifelse(!is.null(sr$sim1$n500[[m]]$empirical.both), TRUE, FALSE)

  plot.data <- cbind(
    if(empirical.both) t(array(as.numeric(sapply(sr, function(x) sapply(x, function(xx) unlist(xx[[m]]$empirical.both[1])))),
                               dim=c(nss, nsim))) else matrix(NA, nsim, nss),
    if(m != "boot0.632.cal") t(array(as.numeric(sapply(sr, function(x) sapply(x, function(xx) unlist(xx[[m]]$true.both[1])))),
                                     dim=c(nss, nsim))) else matrix(NA, nsim, nss),
    if(empirical.both) t(array(as.numeric(sapply(sr, function(x) sapply(x, function(xx) unlist(xx[[m]]$empirical.both[2])))),
                               dim=c(nss, nsim))) else matrix(NA, nsim, nss),
    if(true.both) t(array(as.numeric(sapply(sr, function(x) sapply(x, function(xx) unlist(xx[[m]]$true.both[2])))),
                          dim=c(nss, nsim))) else matrix(NA, nsim, nss))

  plot.data <- plot.data[ ,as.numeric(matrix(1:12, 4, 3, byrow = TRUE))]

  msd <- cbind(
    apply(plot.data[,columns], 2, function(x) mean(x, trim=.1)),
    apply(plot.data[,columns], 2, function(x) sd(Trim(x, trim=.1))))

  msd <- data.frame("mean"=msd[,1], "sd"=msd[,2],
                    upp=msd[,1]+1*msd[,2], low=msd[,1]-1*msd[,2],
                    "statistic"=factor(rep(c("emp.int", "true.int", "emp.slope", "true.slope"), 3),
                                       levels=c("emp.int", "true.int", "emp.slope", "true.slope")),
                    "sample.size"=factor(rep(sample.sizes, each=4)))

  if(print.msd){
    print(msd)
  }

  if(!is.null(ellipsis$ylab)) ylab <- ellipsis$ylab else ylab <- ""
  if(!is.null(ellipsis$title)) title <- ellipsis$title else title <- ""

  ggplot(msd, aes(x=statistic, y=mean, group=sample.size, colour=sample.size)) +
    geom_point(position=position_dodge(width=0.7)) +
    geom_errorbar(aes(x=statistic, ymax=upp, ymin=low), na.rm=TRUE, position=position_dodge(width=0.7)) +
    theme_bw() + ylim(ylim) +
    guides(x =  guide_axis(angle = 45)) +
    labs(x = "",y=ylab, title=title, col="Sample size") +
    scale_x_discrete(labels = c(
      bquote(hat(beta)[.(0)]),
      bquote(beta[.(0)]),
      bquote(hat(beta)[.(1)]),
      bquote(beta[.(1)]))) +
    theme(text = element_text(size=14),
          axis.text.x=element_text(size=rel(1.3)),
          axis.text.y=element_text(size=rel(1.3)))
}
columns <- 1:12
layout <- "
AAABBBCCCC
#DDD#FFF##
"
ylim <- c(-.8, 2.0)
p1 <- plot.cal(sr, "apparent.cal", columns, ylim=ylim, title="Apparent (DGM1)", ylab="Coefficient")
# p2 <- plot.cal(sr, "ext1.app.cal", columns, param=2, ylim=ylim, title="External data DGM1")
# p3 <- plot.cal(sr, "ext2.app.cal", columns, param=2, ylim=ylim, title="External data DGM2")
p4 <- plot.cal(sr, "boot0.632.cal", columns, ylim=ylim, title="Bootstrap\n0.632+")
p5 <- plot.cal(sr, "boot.opt.cal", columns, ylim=ylim, title="Bootstrap\nOptimism corrected")
p6 <- plot.cal(sr, "ext1.total.cal", columns, ylim=ylim, title="External data DGM1", ylab="Coefficient")
p7 <- plot.cal(sr, "ext2.total.cal", columns, ylim=ylim, title="External data DGM2")
pl <- p1 + p4 + p5 + p6 + p7 +
  plot_layout(guides = "collect", design=layout) &
  theme(legend.position = "bottom")
pl


## Plot as deviation from estimands
plot.cal <- function(sr, m, columns, print.msd=TRUE, ylim=NULL, ...){

  ellipsis <- list(...)

  empirical.both <- ifelse(!is.null(sr$sim1$n500[[m]]$empirical.both), TRUE, FALSE)
  true.both <- ifelse(!is.null(sr$sim1$n500[[m]]$empirical.both), TRUE, FALSE)

  plot.data <- cbind(
    if(empirical.both) t(array(as.numeric(sapply(sr, function(x) sapply(x, function(xx) unlist(xx[[m]]$empirical.both[1])))),
                               dim=c(nss, nsim))) else matrix(NA, nsim, nss),
    if(m != "boot0.632.cal") t(array(as.numeric(sapply(sr, function(x) sapply(x, function(xx) unlist(xx[[m]]$true.both[1])))),
                                     dim=c(nss, nsim))) else matrix(NA, nsim, nss),
    if(empirical.both) t(array(as.numeric(sapply(sr, function(x) sapply(x, function(xx) unlist(xx[[m]]$empirical.both[2])))),
                               dim=c(nss, nsim))) else matrix(NA, nsim, nss),
    if(true.both) t(array(as.numeric(sapply(sr, function(x) sapply(x, function(xx) unlist(xx[[m]]$true.both[2])))),
                          dim=c(nss, nsim))) else matrix(NA, nsim, nss))

  plot.data <- plot.data[ ,as.numeric(matrix(1:12, 4, 3, byrow = TRUE))]

  plot.data <- plot.data[ ,c(1,3,5,7,9,11)] - plot.data[ ,c(2,4,6,8,10,12)]

  msd <- cbind(
    apply(plot.data, 2, function(x) mean(x, trim=.1)),
    apply(plot.data, 2, function(x) sd(Trim(x, trim=.1))))

  msd <- data.frame("mean"=msd[,1], "sd"=msd[,2],
                    upp=msd[,1]+1*msd[,2], low=msd[,1]-1*msd[,2],
                    "statistic"=factor(rep(c("int", "slope"), 3),
                                       levels=c("int", "slope")),
                    "sample.size"=factor(rep(sample.sizes, each=2)))

  if(print.msd){
    print(msd)
  }

  if(!is.null(ellipsis$ylab)) ylab <- ellipsis$ylab else ylab <- ""
  if(!is.null(ellipsis$title)) title <- ellipsis$title else title <- ""

  # https://astrostatistics.psu.edu/su07/R/html/grDevices/html/plotmath.html
  ggplot(msd, aes(x=statistic, y=mean, group=sample.size, colour=sample.size)) +
    geom_hline(yintercept=0, linetype="dashed",
               color = "grey", size=1) +
    geom_point(position=position_dodge(width=0.7)) +
    geom_errorbar(aes(x=statistic, ymax=upp, ymin=low), na.rm=TRUE, position=position_dodge(width=0.7)) +
    theme_bw() + ylim(ylim) +
    guides(x =  guide_axis(angle = 45)) +
    labs(x = "",y=ylab, title=title, col="Sample size") +
    scale_x_discrete(labels = c(
      bquote(hat(beta)[.(0)]),
      bquote(hat(beta)[.(1)]))) +
    theme(text = element_text(size=14),
          axis.text.x=element_text(size=rel(1.3)),
          axis.text.y=element_text(size=rel(1.3)))
}
layout <- "
AAABBBCCCC
#DDD#FFF##
"
ylim <- c(-.75, .75)
p1 <- plot.cal(sr, "apparent.cal", columns, ylim=ylim, title="Apparent (DGM1)", ylab="Deviation from estimand")
# p2 <- plot.cal(sr, "ext1.app.cal", columns, param=2, ylim=ylim, title="External data DGM1")
# p3 <- plot.cal(sr, "ext2.app.cal", columns, param=2, ylim=ylim, title="External data DGM2")
p4 <- plot.cal(sr, "boot0.632.cal", columns, ylim=ylim, title="Bootstrap\n0.632+")
p5 <- plot.cal(sr, "boot.opt.cal", columns, ylim=ylim, title="Bootstrap\nOptimism corrected")
p6 <- plot.cal(sr, "ext1.total.cal", columns, ylim=ylim, title="External data DGM1", ylab="Deviation from estimand")
p7 <- plot.cal(sr, "ext2.total.cal", columns, ylim=ylim, title="External data DGM2")
pl <- p1 + p4 + p5 + p6 + p7 +
  plot_layout(guides = "collect", design=layout) &
  theme(legend.position = "bottom")
pl

rmse.cal <- function(sr, m, pl=FALSE, digits=NULL, ...){
  ellipsis <- list(...)

  empirical.both <- ifelse(!is.null(sr$sim1$n500[[m]]$empirical.both), TRUE, FALSE)
  true.both <- ifelse(!is.null(sr$sim1$n500[[m]]$empirical.both), TRUE, FALSE)

  rmse.data <- cbind(
    if(empirical.both) t(array(as.numeric(sapply(sr, function(x) sapply(x, function(xx) unlist(xx[[m]]$empirical.both[1])))),
                               dim=c(nss, nsim))) else matrix(NA, nsim, nss),
    if(m != "boot0.632.cal") t(array(as.numeric(sapply(sr, function(x) sapply(x, function(xx) unlist(xx[[m]]$true.both[1])))),
                                     dim=c(nss, nsim))) else matrix(NA, nsim, nss),
    if(empirical.both) t(array(as.numeric(sapply(sr, function(x) sapply(x, function(xx) unlist(xx[[m]]$empirical.both[2])))),
                               dim=c(nss, nsim))) else matrix(NA, nsim, nss),
    if(true.both) t(array(as.numeric(sapply(sr, function(x) sapply(x, function(xx) unlist(xx[[m]]$true.both[2])))),
                          dim=c(nss, nsim))) else matrix(NA, nsim, nss))

  rmse.data <- rmse.data[ ,as.numeric(matrix(1:12, 4, 3, byrow = TRUE))]

  colnames(rmse.data) <- paste0(rep(c("beta0hat", "beta0hat", "beta1hat", "beta1hat"), 3),
                                paste0("_n", rep(sample.sizes, each=2)))


  err <- rmse.data[ ,c(1,3,5,7,9,11)] - rmse.data[ ,c(1,3,5,7,9,11)+1]

  err <- err[ ,c(1,3,5,2,4,6)]

  # Trim
  err.list <- lapply(1:ncol(err), function(x) Trim(err[ ,x], trim=.1))
  err <- cbind(err.list[[1]], err.list[[2]], err.list[[3]], err.list[[4]], err.list[[5]], err.list[[6]])

  if(pl){
    if(sum(is.na(err)) == 0){
      matplot(apply(err, 2, function(x) sqrt(cumsum(x^2) / (1:length(x)))), type="l", main=paste(m, param))
    } else {
      plot.new()
    }
  }

  # rmse
  out <- apply(err, 2, function(x) sqrt(mean(x^2)))

  names(out) <- rep(paste0("n", sample.sizes), each=2)
  return(out)
}

cal.list <- c("apparent.cal", "boot0.632.cal", "boot.opt.cal", "ext1.total.cal",
              "ext2.total.cal")

# rmse for the intercept estimates
xtable(t(sapply(cal.list, function(m){
  xx <- t(rmse.cal(sr, m, pl=F, digits=3))
})))
