
library(openxlsx)

# Process clock_hannum {DOI: 10.1016/j.molcel.2012.10.016}

data <- read.xlsx("data/mmc2-2.xlsx")
data <- data[, c(1,6)]
colnames(data) <- c("cpg", "coef")

saveRDS(data, "input/hannum.rds")

# Process clock_horvath {}

data <- read.csv("data/13059_2013_3156_MOESM3_ESM.csv", skip = 2)[-1, ]
data <- data[, c(1,2)]
colnames(data) <- c("cpg", "coef")

saveRDS(data, "input/horvath.rds")

