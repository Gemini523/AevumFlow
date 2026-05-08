
library(openxlsx)

# Process clock_hannum {DOI: 10.1016/j.molcel.2012.10.016}

data <- read.xlsx("data/mmc2-2.xlsx")
data <- data[, c(1,6)]
colnames(data) <- c("cpg", "coef")

saveRDS(data, "input/hannum.rds")

