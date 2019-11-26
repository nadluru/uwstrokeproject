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

library(LaplacesDemon)
px <- dnorm(runif(100),0,1)
py <- dnorm(runif(100),0.1,0.9)
KLD(px,py)

library(entropy)