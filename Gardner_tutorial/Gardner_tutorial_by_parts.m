%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make simulated data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% some variables
iNeuron = 1;
orientations = 0:179;
k = 10;
% loop over each neuron tuning function
for orientPreference = 0:2:179  
  % compute the neural response as a Von Mises function
  %Note the 2 here which makes it so that our 0 - 180 orientation
  % space gets mapped to all 360 degrees
  neuralResponse(iNeuron,:) = exp(k*cos(2*pi*(orientations-orientPreference)/180));
  % normalize to a height of 1
  neuralResponse(iNeuron,:) = neuralResponse(iNeuron,:) / max(neuralResponse(iNeuron,:));
  % update counter
  iNeuron = iNeuron + 1;
end
 
% plot the response of neuron 45
figure;
plot(orientations,neuralResponse(45,:));
xlabel('Orientation');
ylabel('Channel response (normalized units to 1)');
 
% make a random weighting of neurons on to each voxel
nNeurons = size(neuralResponse,1);
nVoxels = 50;
neuronToVoxelWeights = rand(nNeurons,nVoxels);

% HERE. EXTRA STEP TO COMPARE THIS CODE WITH THE PYTHON ONE
writematrix(neuronToVoxelWeights);
type 'neuronToVoxelWeights.txt'

%%%%%%%%%% 
%% 
% make stimulus array
nStimuli = 8;
% evenly space stimuli
stimuli = 0:180/(nStimuli):179;
% number of repeats
nRepeats = 20;
stimuli = repmat(stimuli,1,nRepeats);
 
% round and make a column array
stimuli = round(stimuli(:))+1;
 
% compute the voxelResponse
nTrials = nStimuli * nRepeats;
for iTrial = 1:nTrials
  % get the neural response to this stimulus, by indexing the correct column of the neuralResponse matrix
  thisNeuralResponse = neuralResponse(:,stimuli(iTrial));
  % multiply this by the neuronToVoxelWeights to get the voxel response on this trial. Note that you need
  % to get the matrix dimensions right, so transpose is needed on thisNeuralResponse
  voxelResponse(iTrial,:) = thisNeuralResponse' * neuronToVoxelWeights;
end
 
% plot the voxelResponse for the 7th trial
figure;
plot(voxelResponse(7,:));
xlabel('Voxel (number)');
ylabel('Voxel response (fake measurement units)');
%% 
% plot another trial voxel response
figure;
plot(voxelResponse(7,:),'b-.');
hold on
plot(voxelResponse(7+nStimuli,:),'r-o');
xlabel('Voxel (number)');
ylabel('Voxel response (fake measurement units)');
%% 
% add noise to the voxel responses
noiseStandardDeviation = 0.05;
% normalize response 
voxelResponse = voxelResponse / mean(voxelResponse(:));
% add gaussian noise
voxelResponse = voxelResponse + noiseStandardDeviation*randn(size(voxelResponse));

% HERE. EXTRA STEP TO COMPARE THIS CODE WITH THE PYTHON ONE
writematrix(voxelResponse);
type 'voxelResponse.txt'
%% 
% check the voxelResponses
figure;
stim1 = 7;
stim2 = 3;
subplot(1,3,1);
plot(voxelResponse(stim1,:),'b-.');
hold on
plot(voxelResponse(stim1+nStimuli,:),'r-o');
xlabel('Voxel (number)');
ylabel('Voxel response (fake measurement units)');

subplot(1,3,2);
plot(voxelResponse(stim1,:),voxelResponse(stim1+nStimuli,:),'k.');
xlabel('Response to first presentation');
ylabel('Response to second presentation');
axis square
 
subplot(1,3,3);
plot(voxelResponse(stim1,:),voxelResponse(stim2,:),'k.');
xlabel(sprintf('Response to stimulus: %i deg',stimuli(stim1)));
ylabel(sprintf('Response to stimulus: %i',stimuli(stim2)));
axis square
%% 
% Encoding model!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make encoding model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make channel basis functions
nChannels = 8;
exponent = 7;
orientations = 0:179;
prefOrientation = 0:180/nChannels:179;
% loop over each channel
for iChannel = 1:nChannels
  % get sinusoid. Note the 2 here which makes it so that our 0 - 180 orientation
  % space gets mapped to all 360 degrees
  thisChannelBasis =  cos(2*pi*(orientations-prefOrientation(iChannel))/180);
  % rectify
  thisChannelBasis(thisChannelBasis<0) = 0;
  % raise to exponent
  thisChannelBasis = thisChannelBasis.^exponent;
  % keep in matrix
  channelBasis(:,iChannel) = thisChannelBasis;
end
 
% plot channel basis functions
figure;
plot(orientations,channelBasis);
xlabel('Preferred orientation (deg)');
ylabel('Ideal channel response (normalized to 1)');
%% 
% compute the channelResponse for each trial
for iTrial = 1:nTrials
  channelResponse(iTrial,:) = channelBasis(stimuli(iTrial),:);
end
 
% compute estimated weights
estimatedWeights =  pinv(channelResponse) * voxelResponse;
 
% compute model prediction
modelPrediction = channelResponse * estimatedWeights;
% compute residual
residualResponse = voxelResponse-modelPrediction;
% compute r2
r2 = 1-var(residualResponse(:))/var(voxelResponse(:))
%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inverted encoding model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% split half into train and test
firstHalf = 1:round(nTrials/2);
secondHalf = round(nTrials/2)+1:nTrials;
trainVoxelResponse = voxelResponse(firstHalf,:);
testVoxelResponse = voxelResponse(secondHalf:end,:);
% compute weights on train data
estimatedWeights = pinv(channelResponse(firstHalf,:))*trainVoxelResponse;
 
% compute channel response from textVoxelResponses
estimatedChannelResponse = testVoxelResponse * pinv(estimatedWeights);
 
% plot channel responses
figure;colors = hsv(nStimuli);
for iStimuli = 1:nStimuli
  plot(prefOrientation,mean(estimatedChannelResponse(iStimuli:nStimuli:end,:),1),'-','Color',colors(iStimuli,:));
  hold on
end
xlabel('Channel orientation preference (deg)');
ylabel('Estimated channel response (percentile of max)');
title(sprintf('r2 = %0.4f',r2));
%% 
% Compute voxel response without noise
nTrials = nStimuli * nRepeats;
for iTrial = 1:nTrials
  % get the neural response to this stimulus, by indexing the correct column of the neuralResponse matrix
  thisNeuralResponse = neuralResponse(:,stimuli(iTrial));
  % multiply this by the neuronToVoxelWeights to get the voxel response on this trial. Note that you need
  % to get the matrix dimensions right, so transpose is needed on thisNeuralResponse
  voxelResponseNoisy(iTrial,:) = thisNeuralResponse' * neuronToVoxelWeights;
end
 %%
% add noise
noiseStandardDeviation = 0.5;
% normalize response 
voxelResponseNoisy = voxelResponseNoisy / mean(voxelResponseNoisy(:));
% add gaussian noise
voxelResponseNoisy = voxelResponseNoisy + noiseStandardDeviation*randn(size(voxelResponseNoisy));
 % HERE. EXTRA STEP TO COMPARE THIS CODE WITH THE PYTHON ONE
writematrix(voxelResponseNoisy);
type 'voxelResponseNoisy.txt'
%% % split into train and tes
trainVoxelResponseNoisy = voxelResponseNoisy(firstHalf,:);
testVoxelResponseNoisy = voxelResponseNoisy(secondHalf:end,:);
 
% compute weights on train data
estimatedWeights = pinv(channelResponse(firstHalf,:))*trainVoxelResponseNoisy;
 
% compute model prediction on test data
modelPrediction = channelResponse(secondHalf,:) * estimatedWeights;
% compute residual
residualResponse = testVoxelResponseNoisy-modelPrediction;
% compute r2
r2 = 1-var(residualResponse(:))/var(testVoxelResponseNoisy(:))
 
% invert model and compute channel response
estimatedChannelResponse = testVoxelResponseNoisy * pinv(estimatedWeights);
%% 
% plot estimated channel profiles
figure;colors = hsv(nStimuli);
for iStimuli = 1:nStimuli
  plot(prefOrientation,mean(estimatedChannelResponse(iStimuli:nStimuli:end,:),1),'-','Color',colors(iStimuli,:));
  hold on
end
xlabel('Channel orientation preference (deg)');
ylabel('Estimated channel response (percentile of max)');
title(sprintf('r2 = %0.4f',r2));
%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% stimulus likelihood function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% split half into train and test
firstHalf = 1:round(nTrials/2);
secondHalf = round(nTrials/2)+1:nTrials;
trainVoxelResponse = voxelResponse(firstHalf,:);
testVoxelResponse = voxelResponse(secondHalf:end,:);
 
% compute weights on train data
estimatedWeights = pinv(channelResponse(firstHalf,:))*trainVoxelResponse;
 
% compute model prediction on test data
modelPrediction = channelResponse(secondHalf,:) * estimatedWeights;
% compute residual
residualResponse = testVoxelResponseNoisy-modelPrediction;
% compute residual variance, note that this is a scalar
residualVariance = var(residualResponse(:));
 
% make this into a covariance matrix in which the diagonal contains the variance for each voxel
% and off diagonals (in this case all 0) contain covariance between voxels
modelCovar = eye(nVoxels)*residualVariance;
%% % cycle over each trial
nTestTrials = size(testVoxelResponse,1);
for iTrial = 1:nTestTrials
  % now cycle over all possible orientation
  for iOrientation = 1:179
    % compute the mean voxel response predicted by the channel encoding model
    predictedResponse = channelBasis(iOrientation,:)*estimatedWeights;
    % now use that mean response and the model covariance to estimate the probability
    % of seeing this orientation given the response on this trial
    likelihood(iTrial,iOrientation) = mvnpdf(testVoxelResponse(iTrial,:),predictedResponse,modelCovar);
  end
end
 
figure
for iStimuli = 1:nStimuli
  plot(1:179,mean(likelihood(iStimuli:nStimuli:end,:),1),'-','Color',colors(iStimuli,:));
  hold on
end
xlabel('stimulus orientation (deg)');
ylabel('probability given trial response');
%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inverted Encoding model with different channel basis functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% reweight the channels
channelReweighting = [0 0.8 0.4 0 0 0 0.4 0.8]';
% make into a full matrix xform to transform the original channels
for iChannel = 1:nChannels
  xform(iChannel,:) = circshift(channelReweighting,iChannel-1);
end
% and get new bimodal channels
bimodalChannelBasis = channelBasis * xform;
 
% display a figure with one of the channels
figure
plot(orientations,bimodalChannelBasis(:,5));
xlabel('orientation (deg)');
ylabel('Channel response (normalized to 1)');
%% 
% compute the channelResponse for each trial
for iTrial = 1:nTrials
  channelResponse(iTrial,:) = bimodalChannelBasis(stimuli(iTrial),:);
end
 
% compute estimated weights
estimatedWeights =  pinv(channelResponse) * voxelResponse;
 
% compute model prediction
modelPrediction = channelResponse * estimatedWeights;
% compute residual
residualResponse = voxelResponse-modelPrediction;
% compute r2
r2 = 1-var(residualResponse(:))/var(voxelResponse(:))
 
% compute estimated channel response profiles
estimatedChannelResponse = testVoxelResponse * pinv(estimatedWeights);
 
% and plot one of the channels averaged across all trials
figure;
plot(prefOrientation,mean(estimatedChannelResponse(5:nStimuli:end,:),1));
xlabel('Channel preferred orientation (deg)');
ylabel('Estimated channel response (percentile of full)');
title(sprintf('r2 = %0.4f',r2));
%% 
%o compute weights on train data
estimatedWeights = pinv(channelResponse(firstHalf,:))*trainVoxelResponse;
 
% compute model prediction on test data
modelPrediction = channelResponse(secondHalf,:) * estimatedWeights;
% compute residual
residualResponse = testVoxelResponseNoisy-modelPrediction;
% compute residual variance, note that this is a scalar
residualVariance = var(residualResponse(:));
 
% make this into a covariance matrix in which the diagonal contains the variance for each voxel
% and off diagonals (in this case all 0) contain covariance between voxels
modelCovar = eye(nVoxels)*residualVariance;
 
% cycle over each trial
nTestTrials = size(testVoxelResponse,1);
for iTrial = 1:nTestTrials
  % now cycle over all possible orientation
  for iOrientation = 1:179
    % compute the mean voxel response predicted by the channel encoding model
    predictedResponse = bimodalChannelBasis(iOrientation,:)*estimatedWeights;
    % now use that mean response and the model covariance to estimate the probability
    % of seeing this orientation given the response on this trial
    likelihood(iTrial,iOrientation) = mvnpdf(testVoxelResponse(iTrial,:),predictedResponse,modelCovar);
  end
end
 
% now plot the likelihood function averaged over repeats
figure
for iStimuli = 1:nStimuli
  plot(1:179,mean(likelihood(iStimuli:nStimuli:end,:),1));
  hold on
end
xlabel('stimulus orientation (deg)');
ylabel('probability given trial response');
%% 
% THE END