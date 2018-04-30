# Bankruptcy  Prediction  using  Time  Series  Analysis

**Author: Chenxi Ge, David Kes, Chuan Xu, Zhengjie Xu**

## Background and Data
The goal of this project is to forecast Canadian monthly bankruptcy rates for the year 2011 and 2012 using a time series model.

The primary data for constructing the model is the Canadian monthly bankruptcy rates from January 1987 to December 2010. Other data used are: unemployment rate, population size, and housing price index (HPI), all in the same time span as the bankruptcy data.

<p align="center">
<img src="/images/EDA.png" width="700">
</p>

The plot above provides insights on trend and seasonality of each variable. Specifically, the bankruptcy rate shows an increasing trend in the long term and seasonal fluctuations. Also note that the house price index is closely correlated to bankruptcy rate. 

## Models
There are numerous modeling approaches available in forecasting time series data. This report will summarize some of the most common models, highlight the one used as our final model, and discuss what made it the optimal choice. Each model was fit by altering various parameters.

We also expand our framework by utilizing traditional machine learning models like linear regression and XGBoost.

Models we used in our analysis include:

- Univariate Time Series Model
  - SARIMA (Box-Jenkins Approach)
  - Exponential Smoothing (Holt-Winters Approach)
- Multivariate Time Series Model
  - SARIMAX (SARIMA model with external variable)
  - VAR, VARX (Vector Autoregression Approach)
- Traditional Machine Learning Model
  - Linear regression
  - XGBoost

Since our purpose is to predict the bankruptcy rate in the next two years, we would like to maximize the prediction accuracy, which is equivalent to minimizing the prediction errors. The evaluation metric we use is RMSE (root of mean squared errors).  

To choose model, we divide the data into train and validation set as shown below. The final model is selected based on its performance on the validation set.

| | Training | Validation | Test |
| --- | --- | --- | --- |
| Time Period | 22 years (1987-2008) | 2 years (2009-2010) | 2 years (2011-2012) |


**SARIMA** works by removing the trend and seasonality through differencing and then estimates parameters on the transformed data. We first observed the correlation between data points from ACF and PACF plots, and identified potential parameters. Then we built several models and searched for the one with the smallest RMSE on the validation set. SARIMA (4,1,3) (2,1,3) [12] is the optimal SARIMA model.

**Exponential Smoothing** works by assigning exponentially decreasing weights as the observations get older. We specifically used the Triple Exponential Smoothing model that accounts for trend and seasonality. We did an exhaustive search of different combinations of its parameters. Triple exponential smoothing model with (alpha =0.3, beta=0.9, gamma=0.15) is the best one.

**SARIMAX** model is a SARIMA model plus exogenous variables. Exogenous variables are variables that influence the response variable, but the response variable does not influence them. We tried all combinations of exogenous variables and the result shows that models perform best when only using Unemployment Rate as the exogenous variable, with order (3,1,3) (2,1,3) [12].

**VAR** considers external variables as well. Unlike SARIMAX however, it treats all variables as endogenous variables. While SARIMAX only considers the effect the outside variables have on bankruptcy rate, the VAR approach considers all variables as possibly affecting each other. This method simultaneously accounts for these interdependencies. We used all 4 variables (all are considered as endogenous) and searched different time lags to choose the model with the smallest validation set RMSE. VAR(20) is considered best model.

**VARX** considered both exogenous and endogenous variables. Our grid search shows that models perform best when using Bankruptcy Rate and Population as endogenous variables, and Unemployment Rate and Housing Price Index as exogenous variables.

Our **Linear Regression model** uses Month, Year, Unemployment Rate, House Price Index and Population to predict Bankruptcy Rate. After doing variable selection and heuristic exploration, the best model contains Month, Year and Unemployment Rate and interactions among them. 

**XGBoost** is based on gradient boosting framework. It is widely used in solving real-world data problems. The XGBoost model itself turns out to perform worse than linear regression. However, when we first implement linear regression and then use XGBoost to predict the residual of linear regression, the result appears better than linear regression on the validation set.

## Performance

We listed the models and their performance in the table below, sorted by their RMSE.

| Model | Performance |
| --- | ---:|
| VARX | 0.003027 |
| VAR | 0.003112 |
| SARIMAX | 0.003442 |
| SARIMA | 0.003546 |
| Linear Regression | 0.003628 |
| XGBoost | 0.003633 |
| Exponential Smoothing | 0.003832 |

From our observation, VARX provides the best prediction accuracy. It makes sense because VARX model considers both time series effect and linear relationship with exogenous variables. Compared to other models, VARX can capture unexpected spikes (like financial crisis) better.  

We also tried model ensemble to see if it will improve our RMSE. Unfortunately, none of the combinations improved our prediction RMSE on our validation set. Thus, we decided to choose VARX as our final model, and visualized its prediction on the validation set.

<p align="center">
<img src="/images/VARX.png" width="1000">
</p>
