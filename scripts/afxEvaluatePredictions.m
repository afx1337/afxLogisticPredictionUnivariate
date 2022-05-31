function [] = afxEvaluatePredictions(designFile)

    % get design file via ui if not provided
    if ~exist('designFile','var')
        [~,pwdD] = fileparts(pwd);
        if strcmp(pwdD,'scripts'), cd('..'); end
        if ~exist('designFile','var')
            [designF,designP] = uigetfile('data\design.mat','Select design ...');
            designFile = fullfile(designP,designF);
        end
    end
    
    % laod design file
    load(designFile,'design');
    
    % find tici predictor
    idxTici = strcmpi(design.predictors,'tici');
    
    % load analysis mask
    [dat.mask,space.XYZmm,space.dim,space.mat] = afxVolumeLoad(fullfile(design.dataDir,'output',strcat(design.analysisName,'-s',num2str(design.FWHM)),'models','fold001','LogisticGLM_mask_analysis.nii'));
    dat.mask = dat.mask > .5;
    
    % for every patient ...
    pct = floor(length(design.patients)/50);
    s = tic;
    fprintf('Calculating evaluation metrics [');
    for iPatient = 1:length(design.patients)
        % load groundtruth
        fileGroundtruth = design.patients(iPatient).predictions.groundtruth;
        [dat.gt] = afxVolumeLoad(fileGroundtruth);
        dat.gt = dat.gt > .5;
        % get tici score
        tici = design.patients(iPatient).xRaw{idxTici};
        % get prediction maps -> pred
        if tici == 1
            pred.GLM = design.patients(iPatient).predictions.glm(2);
            pred.Thr = design.patients(iPatient).predictions.thr(1);
        else
            pred.GLM = design.patients(iPatient).predictions.glm(1);
            pred.Thr = design.patients(iPatient).predictions.thr(2);
        end
        % write name and predictors to table
        tbl(iPatient).name = design.patients(iPatient).name;
        for iPred = 1:length(design.predictors)
            tbl(iPatient).(['pred',num2str(iPred)]) = design.patients(iPatient).xRaw{iPred};
        end
        %  vertical seperator
        tbl(iPatient).vsep1 = ' ';
        tbl(iPatient).sizeGroundtruth = nnz(dat.gt)*prod(sqrt(sum(space.mat(1:3,1:3).^2)))/1000; % ml
        tbl(iPatient).vsep2 = ' ';
        % write evaluation metrics to table
        predictions = fieldnames(pred);
        for iPrediction = 1:length(predictions)
            % load prediction
            [dat.pred] = afxVolumeLoad(pred.(predictions{iPrediction}).file);
            % evaluation metrics based on continous prediction
            if pred.(predictions{iPrediction}).inverse
                dat.pred(dat.pred == 0) = 2; % treat implicit cbf mask
                tbl(iPatient).(strcat(predictions{iPrediction},'_','ROCAUC')) = afxEvalROCAUC(-dat.pred(dat.mask)',dat.gt(dat.mask)');
            else
                tbl(iPatient).(strcat(predictions{iPrediction},'_','ROCAUC')) = afxEvalROCAUC(dat.pred(dat.mask)',dat.gt(dat.mask)');
            end
            % binarize prediction
            if pred.(predictions{iPrediction}).inverse
                dat.pred = dat.pred < pred.(predictions{iPrediction}).optThr & dat.pred > 0;
            else
                dat.pred = dat.pred > pred.(predictions{iPrediction}).optThr;
            end
            % evaluation metrics based on binarized prediction
            tbl(iPatient).(strcat(predictions{iPrediction},'_AbsVolDiff')) = afxEvalAbsVolDiff(dat.pred(dat.mask)',dat.gt(dat.mask)')*prod(sqrt(sum(space.mat(1:3,1:3).^2)))/1000; % ml
            tbl(iPatient).(strcat(predictions{iPrediction},'_RelVolDiff')) = afxEvalRelVolDiff(dat.pred(dat.mask)',dat.gt(dat.mask)');
            tbl(iPatient).(strcat(predictions{iPrediction},'_Dice')) = afxEvalDice(dat.pred(dat.mask)',dat.gt(dat.mask)');
            tbl(iPatient).(strcat(predictions{iPrediction},'_MCC')) = afxEvalMCC(dat.pred(dat.mask)',dat.gt(dat.mask)');
            tbl(iPatient).(strcat(predictions{iPrediction},'_Dist')) = afxEvalDist(dat.pred',dat.gt',space);
            %  vertical seperator
            if iPrediction < length(predictions), tbl(iPatient).vsep3 = ' '; end
        end
        if mod(iPatient,pct) == 0, fprintf('.'); end
    end
    fprintf('] (%.2f min)\n',toc(s)/60);
    
    % save to disk
	outDir = fullfile(design.dataDir,'output',strcat(design.analysisName,'-s',num2str(design.FWHM)),'evaluation');
    mkdir(outDir);
    tblCell = [fieldnames(tbl)';struct2cell(tbl')'];
    tblCell(1,2:1+length(design.predictors)) = design.predictors;
    xlswrite(fullfile(outDir,'eval.xls'),tblCell);
    predictors = design.predictors;
    save(fullfile(outDir,'eval.mat'),'tbl','predictors');
end