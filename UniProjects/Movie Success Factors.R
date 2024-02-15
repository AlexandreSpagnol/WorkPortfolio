#Library Import
library(tidyverse)  # For data manipulation and visualization
library(broom)     # For tidying regression results
library(GGally)     # For correlation plot
library(readxl)  #read xlsx
library(car)
library(lmtest)
library(ggplot2)  #plotting
library(sandwich) #for heteroscedasticity-robust covariance matrices


# Dataset Import

excel_file_path <- "C:/Users/Filipe Rodrigues/Desktop/Mestrado DS/1º Ano/1º Semestre/Statistics for Data Science/Project/Pesquisa/box_office_final.xlsx"

movies <- read_excel(excel_file_path)

# Display all variables and values
str(movies)

##variable conversions
#adjusting date variable to consider only months
movies$release_month <- as.factor(format(movies$release_Date, "%m"))
# Convert 'release_month' to numeric
movies$release_month <- as.numeric(as.character(movies$release_month))

#convert categorical non dummy features to factors
movies$country <- as.factor(movies$country)
movies$age_rating <- as.factor(movies$age_rating)

#Exploration (Basic Statistic Analysis)
summary(movies)
#for the purpose of multiple linear regression analysis we wont use director,
#writer,actor and name variables so that's why they weren't converted to 
#factors

#boxplot gross income vs months
ggplot(movies, aes(x = factor(release_month), y = gross)) +
  geom_boxplot(outlier.shape = NA) +
  labs(x = "Month", y = "Gross Income") +
  ggtitle("Distribution of Gross Income by Month") +
  scale_y_continuous(
    limits = c(0, 1.0e+09)
  )

#Assess statistical significance between gross income and release month
# ANOVA example
anova_model <- aov(gross ~ release_month, data = movies)
summary(anova_model)
anova_model2 <- aov(log(gross) ~ release_month, data = movies)
summary(anova_model2)

#since we fail to reject h0 we cannot assume that there is a significant 
#difference in gross income between months
#nevertheless, the lowest values in terms of gross income coincide with the dump months
#(january,february,august and september) and the higher income values coincide with the months
#usually associated to be more profitable (july and november). 

##Correlation identification
#eventhough release_month is numerical, it represents months and as such is an 
#ordinal variable so we wont include it in the correlation matrix

cor_matrix <- cor(movies[c('metascore', 'imdb_score', 'votes_imdb', 'runtime', 'budget')])

# Print the correlation matrix
print(cor_matrix)
#we have metascore and imdb_score with 0.67 and votes_imdb and budget with 0.65
#as such votes_imdb and imdb_score will be dropped
#we will preserve metascore over imdb_score since it encompasses a bigger scale of 
#movie rating and as such we will assume it as being more precise
#we will preserve budget over votes_imdb since the last doesnt provide that much valuable
#information

##MLRM (Mulitple Linear Regression Model)
movies_model <- lm(log(gross) ~ age_rating + country + metascore + director_female + writer_female + star_female +
              budget + company_major + runtime + Action + Adventure + Animation + Biography +
              Comedy + Crime + Drama + Family + Fantasy + Horror + Mystery + Thriller + War +
              Romance + Musical + SciFi + Western + Sport+release_month,
            data = movies)

# Print the summary of the regression model
summary(movies_model)

significant_variable_names <- names(coef(movies_model)[summary(movies_model)$coefficients[, "Pr(>|t|)"] < 0.05])
significant_variable_names

##Multicollinearity
# Calculate VIF for all variables in the model
vif_values <- vif(movies_model)
vif_values
#we will drop the variables age_rating and country


movies_model2 <- lm(log(gross) ~ metascore + director_female + writer_female + star_female +
                     budget + company_major + runtime + Action + Adventure + Animation + Biography +
                     Comedy + Crime + Drama + Family + Fantasy + Horror + Mystery + Thriller + War +
                     Romance + Musical + SciFi + Western + Sport+release_month,
                   data = movies)
summary(movies_model2)

##Joint significance
# Define the null hypothesis (at least one coefficient is non-zero)
h0 <- c("metascore = 0", "director_female = 0",
                "writer_female = 0", "star_female = 0", "budget = 0", "company_major = 0",
                "runtime = 0", "Action = 0", "Adventure = 0", "Animation = 0", 
                "Biography = 0", "Comedy = 0", "Crime = 0", "Drama = 0", "Family = 0", 
                "Fantasy = 0", "Horror = 0", "Mystery = 0", "Thriller = 0", "War = 0",
                "Romance = 0", "Musical = 0", "SciFi = 0", "Western = 0", "Sport = 0",
                "release_month = 0")

# joint significance test
#joint_test <- linearHypothesis(movies_model2, h0)

#since we got a warning of 'system is computationally singular' could imply that we have
#variables that we have highly correlated predictors or maybe that one of the variables
#contains extremelly large numbers in comparison with other variables.
#As such, this could be induced by the variable budget so we will try to use another model
#with log (budget)

movies_model3 <- lm(log(gross) ~ metascore + director_female + writer_female + star_female +
                      log(budget) + company_major + runtime + Action + Adventure + Animation + Biography +
                      Comedy + Crime + Drama + Family + Fantasy + Horror + Mystery + Thriller + War +
                      Romance + Musical + SciFi + Western + Sport+release_month,
                    data = movies)
summary(movies_model3)

#introducing log increased both R2 and adjusted r squared automatically, and
#the number of coeficients statiscally significant

# Define the null hypothesis (at least one coefficient is non-zero)
h0_2 <- c("metascore = 0", "director_female = 0",
        "writer_female = 0", "star_female = 0", "log(budget) = 0", "company_major = 0",
        "runtime = 0", "Action = 0", "Adventure = 0", "Animation = 0", 
        "Biography = 0", "Comedy = 0", "Crime = 0", "Drama = 0", "Family = 0", 
        "Fantasy = 0", "Horror = 0", "Mystery = 0", "Thriller = 0", "War = 0",
        "Romance = 0", "Musical = 0", "SciFi = 0", "Western = 0", "Sport = 0",
        "release_month = 0")

# joint significance test
joint_test2 <- linearHypothesis(movies_model3, h0_2)
joint_test2

#we reject h0, so the group of variables included in the regression are jointly significant
#and contribute to explain the variance of the gross income.
#we will disconsidered movies_model and movies_model2 from now on, using only
#movies_model3 as the mlrm

##Homoskedasticity
#we will test homoskedasticity with breusch pagan test and with white special test

#breusch-pagan test

bptest(movies_model3)


#white special test

bptest(movies_model3, ~ fitted(movies_model3) + I(fitted(movies_model3)^2) )
#since this last test had pvalue<0.05 we will rejecth0, so there is evidence that we have 
#heteroscedasticity

##Account for heteroscedasticity
# we will compute heteroscedasticity-robust standard errors and 
#use them for coefficient inference

coef_HC1<-coeftest(movies_model3, vcov = vcovHC(movies_model3, type = "HC1")) #HC1: MacKinnon and White's heteroscedasticity-robust covariance matrix
coef_HC1

#maybe considerar release_month, thriller and horror marginally significant

##RAMSEY TEST for misspecification assessment

reset_movies<-resettest(movies_model3)
reset_movies 

#brief explanation:When you call resettest(movies_model3), it automatically adds squared 
#and cubed terms of the fitted values to the model, and then tests whether these 
#additional terms are jointly significant.
#In this situation since pvalue>0.05 so there is not enough evidence to 
#conclude that your model is misspecified.
#In practical terms, this means that the original linear model appears to be adequately 
#specified, and there is no strong evidence suggesting the need for additional nonlinear 
#terms. 

##zero conditional mean assessment
#we will implement t-test on the mean of residuals to test if it is significantly 
#different from zero, by first storing all residuals in variable residuals.
residuals <- residuals(movies_model3, type = "response", robust = "HC1")
residuals

residual_test <- t.test(residuals)
residual_test

#since pvalue>0.05  there is no significant evidence to reject the null hypothesis
#that the true mean of the residuals is zero. Therefore, we have indication of the validatity of 
#the assumption of a zero conditional mean, indicating that, on average, the residuals are 
#centered around zero. 

summary(movies_model3, robust = "HC1")

##Partial Regression Plots (Statiscally Significant Explanatory Variables)

library(car)

#produce added variable plots
avPlots(movies_model3)

summary(movies_model3)
#here we see that the coefficient estimates are equal on both cases which may indicate
#that heteroscedasticity may not have a substantial impact on our parameter estimates.

## conversions of coefficients
exp(0.018) #metascore
exp(0.946)  #log(budget)
exp(-0.796)  #crime
exp(-2.760)  #war
