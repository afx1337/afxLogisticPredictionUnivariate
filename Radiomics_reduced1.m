clear
addpath('scripts');

% reduction
% #1: Tmax x tici

FWHM = [9 13 5];

[~,space.XYZmm,space.dim,space.mat] = afxVolumeLoad('masks\space2mm_small.nii');

for i = 1:length(FWHM)
    s = tic;
    % design
    load('data\Radiomics_Training_Leipzig\input\demographics\design.mat');
    design.analysisName = 'reduced_model_01';
    design.FWHM = FWHM(i);      % spatial smoothing 5,9,13
    design.nFold = 5;           % number of folds in k-fold cross validation
    design.minPerfusion = 10;   % minimum perfusion maps per parameter
    design.minLesion = .05;     % minimum lesion coverage
    design.interactions(1).val = {'CBF' 'tici'};
    design.interactions(2).val = {'CBV' 'tici'};
    %design.interactions(3).val = {'Tmax' 'tici'};
    % daten laden
    [x,y,masks,design] = afxPrepareDesign(design,space);
    % k-fold crossvalidation (fitting des glms, prediction, abspeichern aller ergebnisse)
    designFile = afxKFold(x,y,masks,space,design);
    % evaluation
    afxEvaluatePredictions(designFile);
    fprintf('Elapsed time is %.1f min.\n',toc(s)/60);
end

rmpath('scripts');