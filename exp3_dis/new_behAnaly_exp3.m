function behAnaly_SL(directory)


if ~exist('directory','var') || isempty(directory) 
	if ~ispc
		directory = '';
	else
		directory = 'H:\Desktop\expData\SL_horVer_20181008\Exp1_20181028\Data\AnalyData\exp3_dis';
	end
end


try

cd(directory);

randLocGroupNum = 1; %%% 1 = merge[nonPair+pairNonReg]
analyBy         = 1;
regularGroup    = 2; %% 2 = random+regular; 
allfiles        = dir(fullfile(pwd,'*.mat'));
allSubData      = [];
allSubAnaly     = [];
allSubDataInfo  = {'subGrp';'subNo';'sessionNo';'blockNo';'IsDistra';'targLoc';'distracLoc';'targShape';
				   'targColor';'targLine';'lineCongruent';'regular';'regularPairedAcc';'acc';'rt';'slowLimit';'fastLimit';
					'inter-trial tt distance';'inter-trial targetShape';'inter-trial targetColor';'inter-trial target hemisphere';'preTrialCorrect';
					'TD distance';'TD hemisphere';'DD distance';'inter-trial DT distance'}; % trial-to-trial relationship

for iMat = 1:size(allfiles,1)
	cFile = allfiles(iMat).name;
	load(cFile);
	cSubData  	= [];
	cSubAnaly 	= []; 
	BlockNum  	= size(designMatrix,3);

	cPair = [4 2; 8 6];
	if ~mod(str2num(subInfo{1}),2) 
		cPair([1 2],:) = cPair([2 1],:);
	end

	for iBlock = 1:BlockNum
		cBlockData   = [repmat(iBlock,size(designMatrix,1),1) squeeze(designMatrix(:,[1:end-1],iBlock))];
		cSubData     = [cSubData;cBlockData];
		cBlockAnaly  = [];

		%%%%%%%%%%%%%%%%%%  calculate trial-by-trial relationship  %%%%%%%%%%%%%%%%%%%%%
	    
		%% cBlockData
	    %% 1'blockNo';
	    %% 2'IsDistra';
	    %% 3'targLoc';
	    %% 4'distracLoc';
	    %% 5'targShape';
	    %% 6'targetColor';
				   
	    %% --------  column 1 = target-target distance ---------/
		for iTrial = 1:size(cBlockData,1)

			if iTrial == 1 % first trial no preTrial
				
				cBlockAnaly(iTrial,1) = 100; 

			else  % nonFirst Trial
				
				cDis = abs(diff(cBlockData([iTrial-1,iTrial],3)));
				if cDis<=4
					cBlockAnaly(iTrial,1) = cDis;
				else 
					cBlockAnaly(iTrial,1) = 8-cDis;
				end
			end
		end
		%%% ----------- distance end --------------\


		%% ----- column 2/3 = target shape/color repeat(1) or switch(0) -------///
		for iTrial = 2:size(cBlockData,1)		
			cBlockAnaly(iTrial,2) = isequal(cBlockData(iTrial,5),cBlockData(iTrial-1,5));
			cBlockAnaly(iTrial,3) = isequal(cBlockData(iTrial,6),cBlockData(iTrial-1,6));
		end				
		%% ---------------------------- target shape/color end ----------------\\\


		%%------- column 4 = trial-to-trial target in same or across hemisphere -------//
		vertMeridianLoc = [2,6];    
		leftHemLoc      = [3:5];


		for iTrial = 2:size(cBlockData,1)

			if diff(cBlockData([iTrial-1,iTrial],3))==0 
				cBlockAnaly(iTrial,4) = 100;
			else
				if numel(intersect(cBlockData([iTrial-1,iTrial],3),vertMeridianLoc))~=0
					cBlockAnaly(iTrial,4) = 3; %% vertical meridian 
				else % nonvertial vertical meridian 
					cBlockAnaly(iTrial,4) = 1+mod(numel(intersect(cBlockData([iTrial-1,iTrial],3),leftHemLoc)),2); % 1=same, 2=cross
				end
			end
			cBlockAnaly(iTrial,5) = acc(iTrial-1,iBlock);
		end	
		%%------------------------- same or across hemisphere ---------------------------\\


		for iTrial = 1:size(cBlockData,1)
			
			if cBlockData(iTrial,2) % isDistractor

				%%%%%%%% target-distractor distance within trial %%%%%%%%%
				TDdis = abs(diff(cBlockData(iTrial,[3,4])));
				if TDdis<=4
					cBlockAnaly(iTrial,6)= TDdis;
				else
					cBlockAnaly(iTrial,6)= 8-TDdis;
				end

				%%%%%%%%% target-distractor in same or across hemisphere  %%%%%%%
				if numel(intersect(cBlockData(iTrial,[3 4]),vertMeridianLoc))~=0
					cBlockAnaly(iTrial,7) = 3; %% vertical meridian 
				else % nonvertial vertical meridian 
					cBlockAnaly(iTrial,7) = 1+mod(numel(intersect(cBlockData(iTrial,[3 4]),leftHemLoc)),2); % 1=same, 2=cross
				end

				%%%%%%%%% distractor-distractor distance between trials  %%%%%%%%
				if iTrial<=size(cBlockData,1)-1
					if ~cBlockData(iTrial+1,2)
						cBlockAnaly(iTrial+1,8) = 100; % no
					else
						DDdis = abs(diff(cBlockData([iTrial,iTrial+1],4)));
						if DDdis<=4
							cBlockAnaly(iTrial+1,8) = (DDdis+1)*10; %%% distractor trial whose prior is distractor-absent has no distance named 0
						else
							cBlockAnaly(iTrial+1,8) = (8-DDdis+1)*10;
						end
					end
				end

				%%%%%%%%% distractor-target distance between trials  %%%%%%%%
				if iTrial<=size(cBlockData,1)-1
					DTdis = abs(diff([cBlockData(iTrial,4),cBlockData(iTrial+1,3)]));
					if DTdis<=4
						cBlockAnaly(iTrial+1,9) = (DTdis+1)*10;  %%% whose prior is distractor-absent has no distance named 0
					else
						cBlockAnaly(iTrial+1,9) = (8-DTdis+1)*10;
					end
				end
			
			end

		end


		%%%%%%%%%%%%%%%%%%   trial-by-trial  or within trial relationship  calculation end %%%%%%%%%%%%%%%%%


		cSubAnaly  = [cSubAnaly;cBlockAnaly];

	end %% iBlock

	cSubData = [repmat([1 str2num(subInfo{1}) str2num(subInfo{2})],size(cSubData,1),1) cSubData]; % 1st column = subGrpBk

	cSubData(cSubData(:,6)==cPair(2,1),12) = 1; %  
	cSubData(cSubData(:,6)==cPair(2,2),12) = regularGroup-1; % after merging two regularities, always 1 = regular 

	cSubData(:,[13:15]) = [ones(size(cSubData,1),1) acc([1:640]') responseTimes([1:640]')*1000];
	allSubData          = [allSubData;cSubData];
	allSubAnaly         = [allSubAnaly;cSubAnaly];

end %% mergeAlldata

allSubData(:,3)         = ceil(allSubData(:,4)/analyBy);


%%% distinguish regular trial types 
regulTrial = find(allSubData(:,12)~=0); % regular trials
for iRegulTrial = regulTrial'
	if regularGroup ==2 
		if randLocGroupNum==2
			allSubData(iRegulTrial-1,12) = 2; % paired-non-regular 
		end
	elseif  regularGroup ==3
		if randLocGroupNum==2
			allSubData(iRegulTrial-1,12) = allSubData(iRegulTrial,12)+2;
		end
	end
	allSubData(iRegulTrial,13) = allSubData(iRegulTrial-1,14); % pairedAcc 
end


%%% report overall accuracy 
% [gm,gsd,gname,corrgcout] = grpstats(allSubData(:,11),{allSubData(:,2)},{'mean','std','gname','numel'});
% mean(gm);



%%% cutoff outliers 
rowFilter = ~~allSubData(:,14);
[gm,gsd,gname,corrgcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2),allSubData(rowFilter,5),allSubData(rowFilter,4)},{'mean','std','gname','numel'}); %  
 gname                   = cellfun(@str2double,gname);
[zscores]                = shiftzs_BCL([corrgcout],0); 

for iRow = 1:size(gname,1)

	conFilter = allSubData(:,2) == gname(iRow,1) & allSubData(:,5) == gname(iRow,2) & allSubData(:,4) == gname(iRow,3);
	allSubData(conFilter,16) = gm(iRow) + gsd(iRow)*zscores(iRow);  % 
	allSubData(conFilter,17) = 200;
end

allSubData = [allSubData allSubAnaly];





% %%%--------- report exclusions % in paper--------------/
rowFilter = ~~allSubData(:,14);
[gm,gsd,gname,corrgcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2)},{'mean','std','gname','numel'}); %  
mean(corrgcout/640);
mean(corrgcout/640)-2.5*std(corrgcout/640)

rowFilter = ~~allSubData(:,14) & allSubData(:,15)<allSubData(:,17); 
[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2)},{'mean','sem','gname','numel'});
mean(gcout)/640

rowFilter = ~~allSubData(:,14) & allSubData(:,15)>allSubData(:,16);
[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2)},{'mean','sem','gname','numel'});
mean(gcout)/640


%%%%%%%%%   overall rt  2.5 SD %%%%
rowFilter = ~~allSubData(:,14) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16); 
[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2)},{'mean','sem','gname','numel'});
mean(gm)+2.5*std(gm);


%%%%%%%%%%%%%	ACC	 %%%%%%%%%%%%%
rowFilter =  ~~allSubData(:,14) ;

[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2),allSubData(rowFilter,5),allSubData(rowFilter,12)},{'mean','sem','gname','numel'});
gname                 = cellfun(@str2double,gname);
trialNum              = repmat(2*[ 72 24  168 56 ]', numel(unique(gname(:,1))),1);
ACC                   = [gname,gcout./trialNum];
accForSpss            = reshape(ACC(:,4),numel(unique(gname(:,2))) * numel(unique(gname(:,3))) ,numel(unique(gname(:,1))))';



%%%%%%%%%%%%%	RT %%%%%%%%%%%%%
rowFilter = ~~allSubData(:,14)  & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) & ismember(allSubData(:,18), [1 2 3 4]);

[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2),allSubData(rowFilter,5),allSubData(rowFilter,12)},{'mean','sem','gname','numel'});
gname                 = cellfun(@str2double,gname);
disRt                 = [gname,gm,gsem,gcout];

[allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(disRt(:,end-2),{disRt(:,2),disRt(:,3)},{'mean','sem','gname','numel'});

RtForSpss             = reshape(gm,4,35)';










cd ..



catch behAnaly_SL_error
		cd ..
		save behAnaly_SL_debug;
		rethrow(behAnaly_SL_error);		
end


end % function