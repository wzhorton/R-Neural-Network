##Cumulative Prototype Code##
#Once the functions are generally operational, they are placed here for testing.
#The commenting and explanations are kept to a minumum


###############################################################################
BuildNet <- function()
{
  nlay <- as.numeric(readline(prompt = "Enter the number of layers in your network (including input layer) : "))
  ninlay <- numeric()
  for(i in 1:nlay)
  {
    n <- as.numeric(readline(prompt = paste("Enter the number of nodes in layer ", i, " : ")))
    ninlay[i] <- n
  }
  biases <- list()
  for(j in 1:(nlay-1))
  {
    biases[[j]] <- rnorm(ninlay[j+1],0,.1)
  }
  
  weights <- list()
  for(k in 1:(nlay-1))
  {
    weights[[k]] <- matrix(rnorm(ninlay[k]*ninlay[k+1],0,.1), nrow = ninlay[k], ncol = ninlay[k+1])
  }
  name <- readline(prompt = "Enter the name of your network : ")
  assign(name, list(weights = weights,biases = biases), envir = .GlobalEnv)
}
###############################################################################
nnpass <- function(input, net)
{
  layers <- length(net$weights)
  activations <- cbind(input)
  for(i in 1:layers)
  {
    z <- t(net$weights[[i]])%*%activations+net$biases[[i]]
    activations <- sigmoid(z)
  }
  return(activations)
}
###############################################################################
sigmoid <- function(z)
{
  return(1/(1+exp(-z)))
}
###############################################################################
d_sig <- function(z)
{
  sigmoid(z)*(1-sigmoid(z))
}
###############################################################################
updateNetworkMini <- function(net, trainData, eta)
{
  layers <- length(net$weights)
  activations <- list()
  activations[[1]] <- trainData$input
  z <- list()
  inreps <-dim(trainData$input)[2]
  if(inreps >1)
  {
    copybiases <- list()
    for(blayer in 1:layers)
    {
      bcopy <- net$biases[[blayer]]
      copybiases[[blayer]] <- bcopy
      for(brep in 2:inreps)
      {
        copybiases[[blayer]] <- cbind(copybiases[[blayer]],bcopy)
      }
    }
  }
  else
  {
    copybiases <- net$biases
  }
  for(i in 1:layers)
  {
    z[[i]] <- t(net$weights[[i]]) %*% activations[[i]] + copybiases[[i]]
    activations[[i+1]] <- sigmoid(z[[i]])
  }
  deltas <- list()
  deltas[[layers]] <- (activations[[layers+1]]-trainData$output) #* d_sig(z[[layers]])#
  for(j in (layers-1):1)
  {
    deltas[[j]] <- (net$weights[[j+1]]%*%deltas[[j+1]]) * d_sig(z[[j]])
  }
  biasgrad <- list()
  for(k in 1:layers)
  {
    sum_matrix <- matrix(1, ncol = 1, nrow = inreps)
    biasgrad[[k]] <- (1/inreps)*(deltas[[k]]%*%sum_matrix)
  }
  weightgrad <- list()
  for(l in 1:layers)
  {
    weightgrad[[l]] <- (1/inreps)*(activations[[l]]%*%t(deltas[[l]]))
  }
  newbiases <- list()
  newweights <- list()
  for(m in 1:layers)
  {
    net$biases[[m]] <- net$biases[[m]] - eta * biasgrad[[m]]
    net$weights[[m]] <- net$weights[[m]] - eta * weightgrad[[m]]
  }
  return(net)
}
###############################################################################
trainNetwork <- function(trainDataTotal, net, eta, epochs, mini_size)
{
  totalIN <- dim(trainDataTotal$input)[2]
  nbatches <- round(totalIN/mini_size)
  
  for(i in 1: epochs)
  {
    shuffled <- sample(1:totalIN,totalIN)
    shuffDataIN <- rbind(trainDataTotal$input[,shuffled])
    shuffDataOUT <- rbind(trainDataTotal$output[,shuffled])
    for(j in 1:nbatches)
    {
      if(j == nbatches)
      {
        minibatchIN <- shuffDataIN[,(mini_size*(nbatches-1)+1):totalIN]
        minibatchOUT <- shuffDataOUT[,(mini_size*(nbatches-1)+1):totalIN]
      }
      else
      {
        minibatchIN <- shuffDataIN[,(mini_size*(j-1)+(1:mini_size))]
        minibatchOUT <- shuffDataOUT[,(mini_size*(j-1)+(1:mini_size))]
      }
      tdata <-list(input = minibatchIN, output = minibatchOUT)
      net <- updateNetworkMini(net,tdata, eta)
    }
    ##Here we will include a test data check for each epoch, giving an accuracy report
  }
  return(net)
}
###############################################################################
###############################################################################

#We now attempt testing on the Titanic data set
train <- read.csv("~/Downloads/train.csv")
test <- read.csv("~/Downloads/test.csv")

clean <- function(dat)
  {
  dat$Ticket <- NULL
  dat$Cabin <- NULL
  dat$Name <- NULL
  dat$PassengerId <- NULL
  #dat <- dat[!is.na(dat$Age),]
  #dat <- dat[!is.na(dat$Fare),]
  dat$Age[is.na(dat$Age)] <- mean(dat$Age[!is.na(dat$Age)])
  dat$Fare[is.na(dat$Fare)] <- mean(dat$Fare[!is.na(dat$Fare)])
  
  genderBin <- function(x)
  {
    if(x == "male") {return(1)}
    else {return(0)}
  }
  embScale <- function(x)
  {
    if(x == "S") {return(1/4)}
    else if(x == "C") {return(2/4)}
    else if(x == "Q") {return(3/4)}
    else {return(4/4)}
  }
  normalize <- function(x)
  {
    mu <- mean(x)
    sig <- sd(x)
    return(((x-mu)/sig)/6)
  }
  dat$Sex <- sapply(dat$Sex, FUN = genderBin)
  dat$Pclass <- dat$Pclass/3
  dat$Embarked <- sapply(dat$Embarked, FUN = embScale)
  dat$Age <- normalize(dat$Age)
  dat$SibSp <- normalize(dat$SibSp)
  dat$Parch <- normalize(dat$Parch)
  dat$Fare <- normalize(dat$Fare)
  return(dat)
}
train <- clean(train)
test <- clean(test)
trainSurv <- rbind(train$Survived)
train$Survived <- NULL

traincheck <- sample(1:length(train$Pclass),length(train$Pclass))
trainTest <- t(train[traincheck[1:100],])
trainTrain <- t(train[traincheck[101:length(traincheck)],])
trainTrainout <- trainSurv[traincheck[101:length(traincheck)]]
trainTestout <- trainSurv[traincheck[1:100]]

tData <- list(input = as.matrix.data.frame(trainTrain), output = rbind(trainTrainout))
#BuildNet()
sv <- numeric()
  for(j in 1:100)
{
titanNet <- trainNetwork(tData,titanNet,.5,1,30) #nets at 7,25,1 optimized
#sum(nnpass(as.matrix.data.frame(trainTest),titanNet) == trainTestout)
saves <- logical()
print(j)
for(i in 1:dim(trainTest)[2])
{
  saves[i] <- 0
   if(as.numeric(round(nnpass(cbind(as.matrix(trainTest[,i])),titanNet))) == trainTestout[i])
   {
     saves[i] <- 1
   }
  #cat(as.numeric(round(nnpass(cbind(as.matrix(trainTest[,i])),titanNet))),"|||",trainTestout[i],"\n")
}
sv[j] <- sum(saves)
}

sv
plot(sv,type = 'l')

testGo <- t(test)
outs <- numeric()
for(k in 1:dim(testGo)[2])
{
  outs[k] <- as.numeric(round(nnpass(as.matrix(testGo[,k]),titanNet)))
}

write.csv(data.frame(PassengerID = 892:1309, Survived = outs),"~/Desktop/NNtitan.csv")

#Now we will use the package neuralnet to do this.

library(neuralnet)
dat3 <- data.frame(rbind(c(0,0,0,0)))
colnames(dat3) <- c("in1","in2","in3","cnt")
for(i in 1:10000)
{
  x <- sample(0:1,3,TRUE)
  newrow <- c(x,sum(x))
  dat3 <- rbind(dat3,newrow)
}


count.net <- neuralnet(cnt ~ in1 + in2 + in3,data = dat3, hidden = 6)
plot(count.net)
compute(count.net,rbind(c(1,1,1)))$net.result
