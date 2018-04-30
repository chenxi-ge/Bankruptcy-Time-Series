library(forecast)
library(vars)

#################### Initial Reading ####################
setwd('/Users/chenxi.ge/Desktop/project/')
train_in <- read.csv("train.csv", header=T)
test_in <- read.csv("test.csv", header=T)

train <- train_in[1:264,]
valid <- train_in[265:288,]

b_train <- ts(data=train$Bankruptcy_Rate, frequency = 12, start = c(1987, 1))
p_train <- ts(data=train$Population, frequency = 12, start = c(1987, 1))
h_train<- ts(data=train$House_Price_Index, frequency = 12, start = c(1987, 1))
u_train <- ts(data=train$Unemployment_Rate, frequency = 12, start = c(1987, 1))

b_valid <- ts(data=valid$Bankruptcy_Rate, frequency = 12, start = c(2009, 1))
p_valid <- ts(data=valid$Population, frequency = 12, start = c(2009, 1))
h_valid <- ts(data=valid$House_Price_Index, frequency = 12, start = c(2009, 1))
u_valid <- ts(data=valid$Unemployment_Rate, frequency = 12, start = c(2009, 1))


#################### SARIMA model (35.46) ####################

# sg = c(1,2,3,4)
# all_rmse <- c()
# label <- c()
# 
# for (p in sg){
#   for (q in sg){
#     for (P in sg){
#       for (Q in sg){
#         print(toString(c(p,1,q,P,1,Q)))
#         my_rmse <- tryCatch(
#           {
#             m <- arima(b_train, order = c(p,1,q), seasonal = list(order = c(P,1,Q), period = 12), method = "CSS-ML")
#             pred <- forecast(m, h = dim(valid)[1], level = 0.95)
#             pred_m <- ts(pred$mean, start = c(2009, 1), frequency = 12)
#             test_rmse <- sqrt(mean((pred_m - b_valid)^2))
#             test_rmse
#           },
#           error = function(cond) {return(1)},
#           warning = function(cond) {return(1)}
#         )
#         label <- c(label, toString(c(p,1,q,P,1,Q)))
#         all_rmse <- c(all_rmse, my_rmse)
#         print(all_rmse)
#       }
#     }
#   }
# }
# df <- data.frame(label, all_rmse)
# df_order <- df[order(df$all_rmse),]
#
# m.null <- arima(b_train, order = c(2,1,1), seasonal = list(order = c(2,1,3), period = 12), method = "CSS-ML")
# m.alt <- arima(b_train, order = c(4,1,3), seasonal = list(order = c(2,1,3), period = 12), method = "CSS-ML")
# 
# D <- -2*(m.null$loglik - m.alt$loglik)
# pval <- 1-pchisq(D,3)

m.sarima <- arima(b_train, order = c(4,1,3), seasonal = list(order = c(2,1,3), period = 12), method = "CSS-ML")
pred.sarima <- forecast(m.sarima, h = dim(valid)[1], level = 0.95)
pred_m.sarima <- ts(pred.sarima$mean, start = c(2009, 1), frequency = 12)
pred_l.sarima <- ts(pred.sarima$lower, start = c(2009, 1), frequency = 12)
pred_u.sarima <- ts(pred.sarima$upper, start = c(2009, 1), frequency = 12)

plot(ts(data=train_in$Bankruptcy_Rate, frequency = 12, start = c(1987, 1)), type = "l", ylab = 'rate')
title(main = "SARIMA model (RMSE = 0.003546)")
points(pred_m.sarima, type = "l", col = "red")
points(pred_l.sarima, type = "l", col = "green")
points(pred_u.sarima, type = "l", col = "green")
points(b_train - m.sarima$residuals, type = "l", col = "blue")

test_rmse.sarima <- sqrt(mean((pred_m.sarima - b_valid)^2))
test_rmse.sarima


#################### Holt-Winters model (38.32) ####################

# step = 0.05
# sg <- seq(step, 1, step)
# all_rmse <- c()
# label <- c()
# 
# for (a in sg) {
#   for (b in sg) {
#     for (c in sg) {
#       m.hw_tmp <- HoltWinters(x = b_train,
#                               alpha = a,
#                               beta = b,
#                               gamma = c,
#                               seasonal = "additive") 
#       pred.hw_tmp <- predict(m.hw_tmp, n.ahead = 24, level = 0.95)
#       pred_m.hw_tmp <- ts(pred.hw_tmp, start = c(2009, 1), frequency = 12)
#       test_rmse.hw_tmp <- sqrt(mean((pred_m.hw_tmp - b_valid)^2))
#       label <- c(label, toString(c(a, b, c)))
#       all_rmse <- c(all_rmse, test_rmse.hw_tmp)
#     }
#   }
# }
# 
# df.hw <- data.frame(label, all_rmse)
# df_order <- df.hw[order(df.hw$all_rmse),]

m.hw <- HoltWinters(x = b_train,
                    alpha = 0.3, beta=0.9, gamma=0.15,
                    seasonal = "add")
pred_m.hw <- predict(m.hw, n.ahead = 24, ci = 0.95)

plot(ts(data=train_in$Bankruptcy_Rate, frequency = 12, start = c(1987, 1)), type = "l", ylab = 'rate')
title(main = "Holt-Winters model (RMSE = 0.003831)")
points(pred_m.hw, type = "l", col = "red")

test_rmse.hw <- sqrt(mean((pred_m.hw - b_valid)^2))
test_rmse.hw


#################### VAR model (31.12) ####################

t <- data.frame(b_train, h_train, u_train, p_train)
v <- data.frame(b_valid, h_valid, u_valid, p_valid)

# all_rmse <- c()
# label <- c()
# 
# for (p in seq(5, 30)){
#   m.var_tmp <- VAR(y = t, lag.max = p, type = 'both', season = 12)
#   pred.var_tmp <- predict(m.var_tmp, n.ahead = 24, ci = 0.95)
#   test_rmse.var_tmp <- sqrt(mean((pred.var_tmp$fcst$b_train[,1] - b_valid)^2))
#   all_rmse <- c(all_rmse, test_rmse.var_tmp)
#   label <- c(label, p)
# }
# df <- data.frame(label, all_rmse)
# df[order(df$all_rmse),]

m.var <- VAR(y = t, lag.max = 20, type = 'both', season = 12)
pred.var <- predict(m.var, n.ahead = 24, ci = 0.95)
pred_m.var <- ts(pred.var$fcst$b_train[,1], start = c(2009, 1), frequency = 12)
pred_l.var <- ts(pred.var$fcst$b_train[,2], start = c(2009, 1), frequency = 12)
pred_u.var <- ts(pred.var$fcst$b_train[,3], start = c(2009, 1), frequency = 12)

plot(ts(data=train_in$Bankruptcy_Rate, frequency = 12, start = c(1987, 1)), type = "l", ylab = 'rate')
title(main = "VAR model (RMSE = 0.003112)")
points(pred_m.var, type = "l", col = "red")
points(pred_l.var, type = "l", col = "green")
points(pred_u.var, type = "l", col = "green")

test_rmse.var <- sqrt(mean((pred_m.var - b_valid)^2))
test_rmse.var


#################### SARIMAX model (34.42) ####################

exo_train <- list(data.frame(X1 = u_train),
                  data.frame(X1 = h_train),
                  data.frame(X1 = p_train),
                  data.frame(X1 = p_train, X2 = u_train),
                  data.frame(X1 = h_train, X2 = u_train),
                  data.frame(X1 = p_train, X2 = h_train),
                  data.frame(X1 = p_train, X2 = h_train, X3 = u_train))

exo_valid <- list(data.frame(X1 = u_valid),
                  data.frame(X1 = h_valid),
                  data.frame(X1 = p_valid),
                  data.frame(X1 = p_valid, X2 = u_valid),
                  data.frame(X1 = h_valid, X2 = u_valid),
                  data.frame(X1 = p_valid, X2 = h_valid),
                  data.frame(X1 = p_valid, X2 = h_valid, X3 = u_valid))

# sg = c(1,2,3,4)
# all_rmse <- c()
# label <- c()
# 
# for (p in sg){
#   for (q in sg){
#     for (P in sg){
#       for (Q in sg){
#         for (j in 1:7){
#           print(paste(toString(c(p,1,q,P,1,Q)), '[', j, ']'))
#           my_rmse <- tryCatch(
#             {
#               m <- arima(b_train,
#                          order = c(p,1,q),
#                          seasonal = list(order = c(P,1,Q),period = 12),
#                          method = "CSS-ML",
#                          xreg = data.frame(exo_train[j]))
#               pred <- forecast(m, h = 24, level = 0.95,
#                                xreg = data.frame(exo_valid[j]))
#               pred_m <- ts(pred$mean, start = c(2009, 1), frequency = 12)
#               test_rmse <- sqrt(mean((pred_m - b_valid)^2))
#               test_rmse
#             },
#             error = function(cond) {return(1)},
#             warning = function(cond) {return(1)}
#           )
#           label <- c(label, paste(toString(c(p,1,q,P,1,Q)), '[', j, ']'))
#           all_rmse <- c(all_rmse, my_rmse)
#           print(all_rmse)
#         }
#       }
#     }
#   }
# }

m.sarimax <- arima(b_train,
           order = c(3,1,3),
           seasonal = list(order = c(2,1,3),period = 12),
           method = "CSS-ML",
           xreg = data.frame(exo_train[1]))
pred.sarimax <- forecast(m.sarimax, h = 24, level = 0.95,
                         xreg = data.frame(exo_valid[1]))
pred_m.sarimax <- ts(pred.sarimax$mean, start = c(2009, 1), frequency = 12)
pred_l.sarimax <- ts(pred.sarimax$lower, start = c(2009, 1), frequency = 12)
pred_u.sarimax <- ts(pred.sarimax$upper, start = c(2009, 1), frequency = 12)

plot(ts(data=train_in$Bankruptcy_Rate, frequency = 12, start = c(1987, 1)), type = "l", ylab = 'rate')
title(main = "SARIMAX model (RMSE = 0.003442)")
points(pred_m.sarimax, type = "l", col = "red")
points(pred_l.sarimax, type = "l", col = "green")
points(pred_u.sarimax, type = "l", col = "green")
points(b_train - m.sarimax$residuals, type = "l", col = "blue")

test_rmse.sarimax <- sqrt(mean((pred_m.sarimax - b_valid)^2))
test_rmse.sarimax


#################### VARX model (30.27) ####################

vary <- list(data.frame(b_train, p_train, h_train),
             data.frame(b_train, p_train, u_train),
             data.frame(b_train, h_train, u_train),
             data.frame(b_train, h_train),
             data.frame(b_train, p_train),
             data.frame(b_train, u_train))

exo_train <- list(data.frame(X1 = u_train),
                  data.frame(X1 = h_train),
                  data.frame(X1 = p_train),
                  data.frame(X1 = p_train, X2 = u_train),
                  data.frame(X1 = h_train, X2 = u_train),
                  data.frame(X1 = p_train, X2 = h_train))

exo_valid <- list(data.frame(X1 = u_valid),
                  data.frame(X1 = h_valid),
                  data.frame(X1 = p_valid),
                  data.frame(X1 = p_valid, X2 = u_valid),
                  data.frame(X1 = h_valid, X2 = u_valid),
                  data.frame(X1 = p_valid, X2 = h_valid))

# index <- c()
# valid_rmse <- c()
# j <- 10
# while(j<=20){
#   i <- 1
#   while(i<=length(vary)) {
#     tryCatch({
#       m.varx_tmp <- VAR(y = vary[[i]], lag.max = j, ic = "AIC", exogen = exo_train[[i]])
#       pred.varx_tmp <- predict(m.varx_tmp,
#                                n.ahead = 24,
#                                ci = 0.95,
#                                dumvar = exo_valid[[i]])$fcst$b_train[,1]
#       rmse.varx_tmp <- sqrt(mean((pred.varx_tmp - b_valid)^2))
#       valid_rmse <- c(valid_rmse, rmse.varx_tmp)
#       index <- c(index, paste('variable set', i, 'lag max', j))
#     },warning = function(w) {
#       print('a warning occured')
#     },error = function(w) {
#       print('an error occured')
#     }
#     )
#     i = i + 1
#   }
#   j = j + 1
# }
# df.varx <- data.frame(index, valid_rmse)
# df.varx[order(df.varx$valid_rmse),]

m.varx <- VAR(y = data.frame(b_train, p_train),lag.max = 14,
             exogen = data.frame(X1 = h_train, X2 = u_train))
pred.varx <- predict(m.varx, n.ahead = 24, ci = 0.95,
                     dumvar = data.frame(X1 = h_valid, X2 = u_valid))

pred_m.varx <- ts(pred.varx$fcst$b_train[,1], start = c(2009, 1), frequency = 12)
pred_l.varx <- ts(pred.varx$fcst$b_train[,2], start = c(2009, 1), frequency = 12)
pred_u.varx <- ts(pred.varx$fcst$b_train[,3], start = c(2009, 1), frequency = 12)

plot(ts(data=train_in$Bankruptcy_Rate, frequency = 12, start = c(1987, 1)), type = "l", ylab = 'rate')
title(main = "VARX model (RMSE = 0.003027)")
points(pred_m.varx, type = "l", col = "red")
points(pred_l.varx, type = "l", col = "green")
points(pred_u.varx, type = "l", col = "green")

test_rmse.varx <- sqrt(mean((pred_m.varx - b_valid)^2))
test_rmse.varx
