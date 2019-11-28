# density vs geom_density ======
library(ggplot2)
#100 random variables
x <- data.frame(x = rnorm(100))
#Calculate own density, set parameters as you desire
d <- density(x$x)
x2 <- data.frame(x = d$x, y = d$y)

#Using geom_density()
ggplot(x, aes(x)) + geom_density()
#Using home grown density
ggplot(x2, aes(x,y)) + geom_line(colour = "red")

# Subject 33 (AD) =====
s33 = csv %>% filter(grepl('033', ID) & MeasureName == 'AD')
d1 = density(s33$Value[which(s33$ROIName == 'Ipsilesional')])
d2 = density(s33$Value[which(s33$ROIName == 'Contralesional')])
s33contra = s33$Value[which(s33$ROIName == 'Contralesional')]
s33ipsi = s33$Value[which(s33$ROIName == 'Ipsilesional')]
plot(d2$x,d2$y)
ggplot(s33, aes(x = Value, color = ROIName, fill = ROIName)) + 
  geom_density(alpha = 0.2)
ggplot(s33, aes(x = Value, color = ROIName, 
                fill = ROIName)) + geom_histogram()
df1 = data.frame(x = d1$x, y = d1$y, r = rep('Ipsi', 512))
df2 = data.frame(x = d2$x, y = d2$y, r = rep('Contra', 512))
df = rbind(df1, df2)
ggplot(df, aes(x = x, y = y, color = r, fill = r)) + 
  geom_point()
KLD(d1$y,d2$y)$mean.sum.KLD
contradiscrete = discretize(s33contra, 20, c(0, 2))
ipsidiscrete = discretize(s33ipsi, 20, c(0, 2))
s33K = 0.5 * (KL.shrink(contradiscrete, ipsidiscrete) + KL.shrink(ipsidiscrete, contradiscrete))


# Subject 33 (MD) =====
s33 = csv %>% filter(grepl('033', ID) & MeasureName == 'MD')
d1 = density(s33$Value[which(s33$ROIName == 'Ipsilesional')])
d2 = density(s33$Value[which(s33$ROIName == 'Contralesional')])
s33contra = s33$Value[which(s33$ROIName == 'Contralesional')]
s33ipsi = s33$Value[which(s33$ROIName == 'Ipsilesional')]
plot(d2$x,d2$y)
ggplot(s33, aes(x = Value, color = ROIName, fill = ROIName)) + 
  geom_density(alpha = 0.2)
ggplot(s33, aes(x = Value, color = ROIName, 
                fill = ROIName)) + geom_histogram()
df1 = data.frame(x = d1$x, y = d1$y, r = rep('Ipsi', 512))
df2 = data.frame(x = d2$x, y = d2$y, r = rep('Contra', 512))
df = rbind(df1, df2)
ggplot(df, aes(x = x, y = y, color = r, fill = r)) + 
  geom_point()
KLD(d1$y,d2$y)$mean.sum.KLD
contradiscrete = discretize(s33contra, 20, c(0, 2))
ipsidiscrete = discretize(s33ipsi, 20, c(0, 2))
s33K = 0.5 * (KL.shrink(contradiscrete, ipsidiscrete) + KL.shrink(ipsidiscrete, contradiscrete))



# Subject 33 (FA) =====
s33 = csv %>% filter(grepl('033', ID) & 
                       MeasureName == 'FA')
d1 = density(s33$Value[which(s33$ROIName == 'Ipsilesional')])
d2 = density(s33$Value[which(s33$ROIName == 'Contralesional')])
s33contra = s33$Value[which(s33$ROIName == 'Contralesional')]
s33ipsi = s33$Value[which(s33$ROIName == 'Ipsilesional')]
plot(d2$x,d2$y)
ggplot(s33, aes(x = Value, color = ROIName, fill = ROIName)) + 
  geom_density(alpha = 0.2)
ggplot(s33, aes(x = Value, color = ROIName, 
                fill = ROIName)) + geom_histogram()
df1 = data.frame(x = d1$x, y = d1$y, r = rep('Ipsi', 512))
df2 = data.frame(x = d2$x, y = d2$y, r = rep('Contra', 512))
df = rbind(df1, df2)
ggplot(df, aes(x = x, y = y, color = r, fill = r)) + 
  geom_point()
KLD(d1$y,d2$y)$mean.sum.KLD
contradiscrete = discretize(s33contra, 20, c(0, 1))
ipsidiscrete = discretize(s33ipsi, 20, c(0, 1))
s33K = 0.5 * (KL.shrink(contradiscrete, ipsidiscrete) + KL.shrink(ipsidiscrete, contradiscrete))

# Subject 36 (AD) ======
s36 = csv %>% filter(grepl('036', ID) & 
                       MeasureName == 'AD')
d1 = density(s36$Value[which(s36$ROIName == 'Ipsilesional')])
d2 = density(s36$Value[which(s36$ROIName == 'Contralesional')])
plot(d2$x,d2$y)
ggplot(s36, aes(x = Value, color = ROIName, fill = ROIName)) + 
  geom_density(alpha = 0.2)
ggplot(s36, aes(x = Value, color = ROIName, 
                fill = ROIName)) + geom_histogram()
df1 = data.frame(x = d1$x, y = d1$y, r = rep('Ipsi', 512))
df2 = data.frame(x = d2$x, y = d2$y, r = rep('Contra', 512))
df = rbind(df1, df2)
ggplot(df, aes(x = x, y = y, color = r, fill = r)) + 
  geom_point()
KLD(d1$y,d2$y)$mean.sum.KLD
s36contra = s36$Value[which(s36$ROIName == 'Contralesional')]
s36ipsi = s36$Value[which(s36$ROIName == 'Ipsilesional')]
contradiscrete = discretize(s36contra, 20, c(0,2))
ipsidiscrete = discretize(s36ipsi, 20, c(0,2))
s36K = 0.5 * (KL.shrink(contradiscrete, ipsidiscrete) + KL.shrink(ipsidiscrete, contradiscrete))

# Subject 36 (MD) ======
s36 = csv %>% filter(grepl('036', ID) & 
                       MeasureName == 'MD')
d1 = density(s36$Value[which(s36$ROIName == 'Ipsilesional')])
d2 = density(s36$Value[which(s36$ROIName == 'Contralesional')])
plot(d2$x,d2$y)
ggplot(s36, aes(x = Value, color = ROIName, fill = ROIName)) + 
  geom_density(alpha = 0.2)
ggplot(s36, aes(x = Value, color = ROIName, 
                fill = ROIName)) + geom_histogram()
df1 = data.frame(x = d1$x, y = d1$y, r = rep('Ipsi', 512))
df2 = data.frame(x = d2$x, y = d2$y, r = rep('Contra', 512))
df = rbind(df1, df2)
ggplot(df, aes(x = x, y = y, color = r, fill = r)) + 
  geom_point()
KLD(d1$y,d2$y)$mean.sum.KLD
s36contra = s36$Value[which(s36$ROIName == 'Contralesional')]
s36ipsi = s36$Value[which(s36$ROIName == 'Ipsilesional')]
contradiscrete = discretize(s36contra, 20, c(0,2))
ipsidiscrete = discretize(s36ipsi, 20, c(0,2))
s36K = 0.5 * (KL.shrink(contradiscrete, ipsidiscrete) + KL.shrink(ipsidiscrete, contradiscrete))

# Subject 36 (FA) ======
s36 = csv %>% filter(grepl('036', ID) & 
                       MeasureName == 'FA')
d1 = density(s36$Value[which(s36$ROIName == 'Ipsilesional')])
d2 = density(s36$Value[which(s36$ROIName == 'Contralesional')])
plot(d2$x,d2$y)
ggplot(s36, aes(x = Value, color = ROIName, fill = ROIName)) + 
  geom_density(alpha = 0.2)
ggplot(s36, aes(x = Value, color = ROIName, 
                fill = ROIName)) + geom_histogram()
df1 = data.frame(x = d1$x, y = d1$y, r = rep('Ipsi', 512))
df2 = data.frame(x = d2$x, y = d2$y, r = rep('Contra', 512))
df = rbind(df1, df2)
ggplot(df, aes(x = x, y = y, color = r, fill = r)) + 
  geom_point()
KLD(d1$y,d2$y)$mean.sum.KLD
s36contra = s36$Value[which(s36$ROIName == 'Contralesional')]
s36ipsi = s36$Value[which(s36$ROIName == 'Ipsilesional')]
contradiscrete = discretize(s36contra, 20, c(0,1))
ipsidiscrete = discretize(s36ipsi, 20, c(0,1))
s36K = 0.5 * (KL.shrink(contradiscrete, ipsidiscrete) + KL.shrink(ipsidiscrete, contradiscrete))
plot(contradiscrete)
plot(ipsidiscrete)



# Subject 22 (RD) =====
s22 = csv %>% filter(grepl('022', ID) & MeasureName == 'RD')
d1 = density(s22$Value[which(s22$ROIName == 'Ipsilesional')])
d2 = density(s22$Value[which(s22$ROIName == 'Contralesional')])
s22contra = s22$Value[which(s22$ROIName == 'Contralesional')]
s22ipsi = s22$Value[which(s22$ROIName == 'Ipsilesional')]
plot(d2$x,d2$y)
ggplot(s33, aes(x = Value, color = ROIName, fill = ROIName)) + 
  geom_density(alpha = 0.2)
ggplot(s33, aes(x = Value, color = ROIName, 
                fill = ROIName)) + geom_histogram()
df1 = data.frame(x = d1$x, y = d1$y, r = rep('Ipsi', 512))
df2 = data.frame(x = d2$x, y = d2$y, r = rep('Contra', 512))
df = rbind(df1, df2)
ggplot(df, aes(x = x, y = y, color = r, fill = r)) + 
  geom_point()
KLD(d1$y,d2$y)$mean.sum.KLD
contradiscrete = discretize(s22contra, 20, c(0, 2))
ipsidiscrete = discretize(s22ipsi, 20, c(0, 2))
plot(contradiscrete)
plot(ipsidiscrete)
s22K = 0.5 * (KL.shrink(contradiscrete, ipsidiscrete) + KL.shrink(ipsidiscrete, contradiscrete))

# Subject 01 (AD) =====
s01 = csv %>% filter(grepl('001', ID) & MeasureName == 'AD')
d1 = density(s01$Value[which(s01$ROIName == 'Ipsilesional')])
d2 = density(s01$Value[which(s01$ROIName == 'Contralesional')])
s01contra = s01$Value[which(s01$ROIName == 'Contralesional')]
s01ipsi = s01$Value[which(s01$ROIName == 'Ipsilesional')]

library(LaplacesDemon)
px <- dnorm(runif(100),0,1)
py <- dnorm(runif(100),0.1,0.9)
KLD(px,py)

library(LaplacesDemon)
csv = read.csv(paste0(csvroot, 'StrokeVoxelwiseDTIDemo_Nov272019.csv'))

# region s16 ad =====
s16 = csv %>% filter(grepl('016', ID) & MeasureName == 'AD')
s16d1 = density(s16$Value[which(s16$ROIName == 'Ipsilesional')],
                from = 0, to = 2, bw = 0.1)
s16d2 = density(s16$Value[which(s16$ROIName == 'Contralesional')],
                from = 0, to = 2, bw = 0.1)
s16d1 = density(s16$Value[which(s16$ROIName == 'Ipsilesional')])
s16d2 = density(s16$Value[which(s16$ROIName == 'Contralesional')])
s16K = KLD(s16d1$y,s16d2$y)$mean.sum.KLD

# region s16 fa =====
s16 = csv %>% filter(grepl('016', ID) & MeasureName == 'FA')
s16d1 = density(s16$Value[which(s16$ROIName == 'Ipsilesional')],
                from = 0, to = 1, bw = 0.05)
s16d2 = density(s16$Value[which(s16$ROIName == 'Contralesional')],
                from = 0, to = 1, bw = 0.05)
s16d1 = density(s16$Value[which(s16$ROIName == 'Ipsilesional')])
s16d2 = density(s16$Value[which(s16$ROIName == 'Contralesional')])
s16K = KLD(s16d1$y,s16d2$y)$mean.sum.KLD

# Does sample size matter for density function ====
x = runif(100, 0, 1)
d = density(x, from = 0, to = 1, bw = 0.1)
x1000 = runif(1000, 0, 1)
d1000 = density(x1000, from = 0, to = 1, bw = 0.1)
x100K = runif(100000, 0, 1)
d100K = density(x100K, from = 0, to = 1, bw = 0.1)

ggplot(rbind(data.frame(x = d$x, y = d$y, s = '100'),
             data.frame(x = d1000$x, y = d1000$y, s = '1000'),
             data.frame(x = d100K$x, y = d100K$y, s = '100K')),
       aes(x, y, color = s)) + geom_point()


f = 1.0
t = 2.0
x = runif(100, f, t)
d2 = density(x, from = 0, to = t, bw = 0.1)
x1000 = runif(1000, f, t)
d21000 = density(x1000, from = 0, to = t, bw = 0.1)
x100K = runif(100000, f, t)
d2100K = density(x100K, from = 0, to = t, bw = 0.1)

ggplot(rbind(data.frame(x = d2$x, y = d2$y, s = '100'),
             data.frame(x = d21000$x, y = d21000$y, s = '1000'),
             data.frame(x = d2100K$x, y = d2100K$y, s = '100K')),
       aes(x, y, color = s)) + geom_point()

KLD(d$y, d2$y)$mean.sum.KLD
KLD(d100K$y, d2100K$y)$mean.sum.KLD
KLD(d1000$y, d21000$y)$mean.sum.KLD
