function behAnaly_SL(directory)


if ~exist('directory','var') || isempty(directory) 
	if ~ispc
		directory = '';
	else
		directory = 'H:\Desktop\expData\SL_horVer_20181008\Exp1_20181028\Data\AnalyData\exp2_noDisCtrl';
	end
end


try

cd(directory);

randLocGroupNum = 1; %% 1 = merge[nonPair+pairNonReg]
analyBy         = 4;
regularGroup    = 2; %% 2 = random+regular;
allfiles        = dir(fullfile(pwd,'*.mat'));
allSubData      = [];
allSubAnaly     = [];
allSubDataInfo  = {'subGrp';'subNo';'sessionNo';'blockNo';'targLoc';'targShape';
				   'targColor';'targLine';'regular';'regularPairedAcc';'acc';'rt';'slowLimit';'fastLimit';
					'distance';'targetShape';'targetColor';'hemisphere';'preTtrialCorrect'}; % trial-to-trial relationship

for iMat = 1:size(allfiles,1)
	cFile = allfiles(iMat).name;
	load(cFile);
	cSubData  	= [];
	cSubAnaly 	= []; 
	BlockNum  	= size(designMatrix,3);

	for iBlock = 1:BlockNum
		cBlockData   = [repmat(iBlock,size(designMatrix,1),1) squeeze(designMatrix(:,[1:end-1],iBlock))];
		cSubData     = [cSubData;cBlockData];
		cBlockAnaly  = [];

		cPair = [4 2; 8 6];

		if ~mod(str2num(subInfo{1}),2) 
			cPair([1 2],:) = cPair([2 1],:);
		end

		%%%%%%%%%%%%%%%%%%  calculate trial-by-trial relationship  %%%%%%%%%%%%%%%%%%%%%
	    
	    %% --------  column 1 = distance ---------/
		for iTrial = 1:size(cBlockData,1)

			if iTrial == 1 % first trial no preTrial
				
				cBlockAnaly(iTrial,1) = 100; 

			else  % nonFirst Trial

				cDis = abs(diff(cBlockData([iTrial-1,iTrial],2)));
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
			cBlockAnaly(iTrial,2) = isequal(cBlockData(iTrial,3),cBlockData(iTrial-1,3));
			cBlockAnaly(iTrial,3) = isequal(cBlockData(iTrial,4),cBlockData(iTrial-1,4));
		end				
		%% ---------------------------- target shape/color end ----------------\\\


		%%------- column 4 = same or across hemisphere -------//
		vertMeridianLoc = [2,6];    
		leftHemLoc      = [3:5];


		for iTrial = 2:size(cBlockData,1)

			if diff(cBlockData([iTrial-1,iTrial],2))==0 
				cBlockAnaly(iTrial,4) = 100;
			else
				if numel(intersect(cBlockData([iTrial-1,iTrial],2),vertMeridianLoc))~=0
					cBlockAnaly(iTrial,4) = 0; %% vertical meridian 
				else % nonvertial vertical meridian 
					cBlockAnaly(iTrial,4) = 1+mod(numel(intersect(cBlockData([iTrial-1,iTrial],2),leftHemLoc)),2); % 1=same, 2=cross
				end
			end
			cBlockAnaly(iTrial,5) = acc(iTrial-1,iBlock);
		end	
		%%------------- same or across hemisphere -----------\\

		%%%%%%%%%%%%%%%%%%   trial-by-trial relationship  calculation end %%%%%%%%%%%%%%%%%


		cSubAnaly  = [cSubAnaly;cBlockAnaly];

	end %% iBlock

	cSubData = [repmat([1 str2num(subInfo{1}) str2num(subInfo{2})],size(cSubData,1),1) cSubData]; % 1st column = subGrpBk

	cSubData(cSubData(:,5)==cPair(2,1),9) = 1; %  
	cSubData(cSubData(:,5)==cPair(2,2),9) = regularGroup-1; % 1= horizontal, 2= vertical ;  after merging two regularities, always 1 = regular
	if randLocGroupNum == 2 & regularGroup ==2
		cSubData(cSubData(:,4)<5 & cSubData(:,5)==cPair(1,1),9) = 2; %  
		cSubData(cSubData(:,4)<5 & cSubData(:,5)==cPair(1,2),9) = 2; %  
	end

	cSubData(:,[10:12]) = [ones(size(cSubData,1),1) acc(:) responseTimes(:)*1000];
	allSubData          = [allSubData;cSubData];
	allSubAnaly         = [allSubAnaly;cSubAnaly];

end %% mergeAlldata

allSubData(:,3)         = ceil(allSubData(:,4)/analyBy);


%%% distinguish regular trial types 
regulTrial = find(allSubData(:,4)>4 & allSubData(:,9)~=0); % regular trials
for iRegulTrial = regulTrial'
	if regularGroup ==2 
		if randLocGroupNum==2
			allSubData(iRegulTrial-1,9) = 2; % paired-non-regular 
		end
	elseif  regularGroup ==3
		if randLocGroupNum==2
			allSubData(iRegulTrial-1,9) = allSubData(iRegulTrial,9)+2;
		end
	end
	allSubData(iRegulTrial,10) = allSubData(iRegulTrial-1,11); % pairedAcc 
end



%%% cutoff outliers 
rowFilter = ~~allSubData(:,11);
[gm,gsd,gname,corrgcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,2), allSubData(rowFilter,4)},{'mean','std','gname','numel'}); % ,allSubData(rowFilter,4)
 gname                   = cellfun(@str2double,gname);
[zscores]                = shiftzs_BCL([corrgcout],0); 

for iRow = 1:size(gname,1)

	conFilter = allSubData(:,2) == gname(iRow,1) & allSubData(:,4) == gname(iRow,2); %%& allSubData(:,9) == gname(iRow,3);
	allSubData(conFilter,13) = gm(iRow) + gsd(iRow)* zscores(iRow);  % zscores(iRow)
	allSubData(conFilter,14) = 200;
end

allSubData = [allSubData allSubAnaly];



% % %%%--------- report exclusions % in paper--------------/
rowFilter = ~~allSubData(:,11);
[gm,gsd,gname,corrgcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,2)},{'mean','std','gname','numel'});
mean(corrgcout)/512;

rowFilter = ~~allSubData(:,11) & allSubData(:,12)<allSubData(:,14); 
[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,2)},{'mean','sem','gname','numel'});

rowFilter = ~~allSubData(:,11) & allSubData(:,12)>allSubData(:,13);
[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,2)},{'mean','sem','gname','numel'});
mean(gcout/512);
%%--------- report exclusions % in paper--------------\

%%%%%   overall rt  2.5 SD %%%%
rowFilter = ~~allSubData(:,14) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16); 
[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2)},{'mean','sem','gname','numel'});
mean(gm)+2.5*std(gm);




%%%%%%%%%%%%%	ACC	 %%%%%%%%%%%%%
rowFilter =  ~~allSubData(:,11);

[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,2),allSubData(rowFilter,3),allSubData(rowFilter,9)},{'mean','sem','gname','numel'});
gname                 = cellfun(@str2double,gname);
trialNum              = repmat([192 64 ]', numel(unique(gname(:,1)))*numel(unique(gname(:,2))),1);
ACC                   = [gname,gcout./trialNum];
accForSpss            = reshape(ACC(:,4),numel(unique(gname(:,2))) * numel(unique(gname(:,3))),numel(unique(gname(:,1))))';


%%%%%%%%%%%%%	RT	%%%%%%%%%%%%%
rowFilter =  ~~allSubData(:,11)  & allSubData(:,12)>allSubData(:,14) & allSubData(:,12)<=allSubData(:,13)  ;

[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,2),allSubData(rowFilter,3),allSubData(rowFilter,9)},{'mean','sem','gname','numel'});

RtForSpss = reshape(gm,numel(unique(gname(:,2))) * numel(unique(gname(:,3))),numel(unique(gname(:,1))))';







cd ..



catch behAnaly_SL_error
		cd ..
		save behAnaly_SL_debug;
		rethrow(behAnaly_SL_error);		
end


end % function