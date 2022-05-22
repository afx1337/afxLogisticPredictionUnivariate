function [x,design] = afxAddInteraction(x,design,interaction)

    for i = 1:length(interaction)
        idxInteraction(i) = find(strcmpi(design.predictors,interaction{i}),1);
        if isempty(idxInteraction(i))
            error(['Interaktion mit unbekanntem Prädiktor "' interaction{i} '".']);
        end
    end
    x(:,end+1,:) = prod(x(:,idxInteraction,:),2);
    design.predictors(end+1) = join(interaction,' x ');
    
    for iPatient = 1:length(design.patients)
        design.patients(iPatient).xRaw{end+1} = 'interaction';
    end
end
