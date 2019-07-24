function behAnaly_SL(directory)

%%  target predict target, gray stimulus with low & high salience distractor 

if ~exist('directory','var') || isempty(directory) 
	if ~ispc
		directory = '/Volumes/LASBK/weekendJob/AnalyData/2seqTpT';
	else
		addpath('H:\Desktop\mytoolbox');
		savepath;
		directory = 'H:\Desktop\expData\SL_horVer_20181008\Exp1_20181028\Data\AnalyData\2seqTpT_gray';
	end
end

cd(directory);

allfiles   = dir(fullfile(pwd,'*.mat'));
allSubData = [];
allSubDataInfo = {'oddEven';'subNo';'sessionNo';'blockNo';'IsDistra';'targLoc';'distracLoc';'targShape';
				'disColor';'targLine';'lineCongruent';'regular';'regularPairedAcc';'acc';'rt'};

analyBy         = 4; % 
regularGroup    = 2; % 2=random+regular; 3=random+horizontal+vertical;
randLocGroupNum = 2;

for iMat = 1:size(allfiles,1)
	cFile = allfiles(iMat).name;
	load(cFile);
	cSubData    = [];

	for iBlock = 1:12
		cBlockData = [repmat(iBlock,size(designMatrix,1),1) squeeze(designMatrix(:,[1:end-1],iBlock))];
		cSubData   = [cSubData;cBlockData];

		%% -------- calculate trial-by-trial distance ---------/
		for iTrial = 1:size(cBlockData,1)
			if iTrial == 1 % first trial no preTrial
				cSubTrialDis(iTrial,iBlock) = 100; 
			else  % nonFirst Trial
				if ~acc(iTrial-1,iBlock) % no relationship with wrong preTrial
					cSubTrialDis(iTrial,iBlock) = 100; 
				else 
					cLoc = cBlockData([iTrial-1,iTrial],3) ;
					if ismember(8,cLoc) 
						cLoc(find(cLoc==8))= 0;
					end
					
					cDis = abs(diff(cLoc));
					if cDis<=4
						cSubTrialDis(iTrial,iBlock) = cDis;
					else 
						cSubTrialDis(iTrial,iBlock) = 8-cDis;
					end
				end
			end
		end
		%%% -------- calculate trial-by-trial distance ---------\
	end

	cSubData = [repmat([2-mod(str2num(subInfo{1}),2) str2num(subInfo{1}) str2num(subInfo{2})],size(cSubData,1),1) cSubData];
	
	if mod(str2num(subInfo{1}),2)
		cSubData(cSubData(:,6)==8,12) = 1; % before: 1 2 3 4
		cSubData(cSubData(:,6)==6,12) = regularGroup-1;
	else
		cSubData(cSubData(:,6)==4,12) = 1;
		cSubData(cSubData(:,6)==2,12) = regularGroup-1;
	end
	cSubData(:,[13:15]) = [ones(size(cSubData,1),1) acc([1:960]') responseTimes([1:960]')*1000];
	cSubData(:,30)      = cSubTrialDis(:);
	allSubData          = [allSubData;cSubData];
end

allSubData(:,3) = ceil(allSubData(:,4)/analyBy);

if randLocGroupNum==1
	regularTrialPerBlock = [18 6;21 7;21 7];
elseif randLocGroupNum==2
	regularTrialPerBlock = [12 6 6; 14 7 7; 14 7 7];
end


regulTrialNum  = [repmat(analyBy*regularTrialPerBlock(1,:)',12/analyBy,1);repmat(analyBy*regularTrialPerBlock(2,:)',12/analyBy,1);repmat(analyBy*regularTrialPerBlock(3,:)',12/analyBy,1)];

% regulTrialNum  = [repmat(analyBy*regularTrialPerBlock(1,:)',12/analyBy,1);repmat(analyBy*regularTrialPerBlock(2,:)',12/analyBy,1);repmat(analyBy*regularTrialPerBlock(3,:)',12/analyBy,1)];

switch analyBy
	case 4 % 4blocks
		x              = [1:3];
		xRange         = [0.3 3.3];
		nRow           = 4;
		rowPerSubgroup = nRow/2; 
		nColm 		   = 7;
	% case 2 % 2 blocks
	% 	x              = [1:6];
	% 	xRange         = [0.3 6.3];
	% 	nRow  		   = 4;
	% 	rowPerSubgroup = nRow/2; 
	% 	nColm 		   = 4;
end

regulTrial = find(allSubData(:,12)~=0);
for iRegulTrial = regulTrial'
	
	if randLocGroupNum==2 % pairNonRegular 
		allSubData(iRegulTrial-1,12) = 2; % 
	end

	% predicted trial
	if isequal(allSubData(iRegulTrial,8),allSubData(iRegulTrial-1,8)) % repeat shape 
		if isequal(allSubData(iRegulTrial,9),allSubData(iRegulTrial-1,9))
			allSubData(iRegulTrial,19) = 1; % repeat color 
		else
			allSubData(iRegulTrial,19) = 2; 
		end
	else % switch shape
		if isequal(allSubData(iRegulTrial,9),allSubData(iRegulTrial-1,9))
			allSubData(iRegulTrial,19) = 3; 
		else
			allSubData(iRegulTrial,19) = 4; 
		end
	end

	if iRegulTrial>2 

		if isequal(allSubData(iRegulTrial-1,4),allSubData(iRegulTrial-2,4)) % have to be in the same block
			
			% predicting trials 
			if isequal(allSubData(iRegulTrial-1,8),allSubData(iRegulTrial-2,8)) % repeat shape 
				if isequal(allSubData(iRegulTrial-1,9),allSubData(iRegulTrial-2,9))
					allSubData(iRegulTrial-1,19) = 1; % repeat color 
				else
					allSubData(iRegulTrial-1,19) = 2; 
				end
			else % switch shape
				if isequal(allSubData(iRegulTrial-1,9),allSubData(iRegulTrial-2,9))
					allSubData(iRegulTrial-1,19) = 3; 
				else
					allSubData(iRegulTrial-1,19) = 4; 
				end
			end
		end
	end
	allSubData(iRegulTrial,18) = allSubData(iRegulTrial-1,5) + 1; % 1st is without(1); 1st is with(2)
	allSubData(iRegulTrial,13) = allSubData(iRegulTrial-1,14);
end



	
rowFilter = ~~allSubData(:,14);

%% cutoff outliers for noDistractor, low & high salience distractor 
[gm,gsd,gname,corrgcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2),allSubData(rowFilter,9),allSubData(rowFilter,3)},{'mean','std','gname','numel'});
 gname                   = cellfun(@str2double,gname);
[zscores]                = shiftzs_BCL([corrgcout],0); 

for iRow = 1:size(gname,1)
   
   conFilter = allSubData(:,2) == gname(iRow,1) & allSubData(:,9) == gname(iRow,2) & allSubData(:,3) == gname(iRow,3) ;
   
   allSubData(conFilter,16) = gm(iRow) + zscores(iRow)*gsd(iRow); 
   allSubData(conFilter,17) = 200;
end


figTitle   = {'genAcc','realAcc'};
xTickLabel = {'S1','S2','S3','S4','S5','S6'}; 


lineColor    = [0 0 0;0 0 0;0 0 200; 0 0 200;255 0 0;255 0 0]/255;
lineStyle    = {'--','--','--','--','--','--'};

if randLocGroupNum ==1
		marker       = {'s','o','s','o','s','o'};
else
		marker       = {'o','s','o','s','o','s'};
end


for iMethod = 1:2
	if iMethod==1 %% general ACC of regular & non-regular of noDistractor & distractor
		
		rowFilter                = ~~allSubData(:,14); % genearal ACC
		[gm,gsd,gname,corrgcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,1),allSubData(rowFilter,2),allSubData(rowFilter,9),allSubData(rowFilter,3),allSubData(rowFilter,12)},{'mean','std','gname','numel'});
		gname                    = cellfun(@str2double,gname);
		genAcc                   = [gname,corrgcout];
		genAcc(:,end+1)          = genAcc(:,end)./repmat(regulTrialNum,numel(unique(allSubData(:,2))),1);

	elseif iMethod==2 %%%  another Acc minus wrong predicting trials
		
		rowFilter                = ~~allSubData(:,13);
		[gm,gsd,gname,realgcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,1),allSubData(rowFilter,2),allSubData(rowFilter,9),allSubData(rowFilter,3),allSubData(rowFilter,12)},{'mean','std','gname','numel'});
		rowFilter                = ~~allSubData(:,14) & allSubData(:,13); 
		[gm,gsd,gname,corrgcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,1),allSubData(rowFilter,2),allSubData(rowFilter,9),allSubData(rowFilter,3),allSubData(rowFilter,12)},{'mean','std','gname','numel'});
		gname                    = cellfun(@str2double,gname);
		genAcc                   = [gname,corrgcout];
		genAcc(:,end+1)          = genAcc(:,end)./realgcout;
	end

	genAccRaw = genAcc;
	genAcc    = genAcc(genAcc(:,5)>0,:); % plot pairs

	[genAccgmCout,genAccgsem,genAccgname,genAccgcout] = grpstats(genAcc(:,end-1),{genAcc(:,1),genAcc(:,3),genAcc(:,4),genAcc(:,5)},{'mean','sem','gname','numel'});
	[genAccgm,genAccgsem,genAccgname,genAccgcout]     = grpstats(genAcc(:,end),{genAcc(:,1),genAcc(:,3),genAcc(:,4),genAcc(:,5)},{'mean','sem','gname','numel'});
	genAccgname  = cellfun(@str2double,genAccgname);
	genAcc([size(genAcc,1)+1:size(genAcc,1)+size(genAccgname,1)],:) = [genAccgname(:,1),genAccgsem,genAccgname(:,[2:4]),genAccgmCout genAccgm]; 
	genAcc_odd  = genAcc(genAcc(:,1)==1,:);
	genAcc_even = genAcc(genAcc(:,1)==2,:);

	%%%%% start to plot genAcc %%%%%
	genAccRange  = [0.6,1];
	ngroups      = numel(unique(genAcc(:,3)))*2;
	ndots        = numel(unique(genAcc(:,4)));   
	oddSubPlot 	 = size(genAcc_odd,1)/(ngroups*ndots);
	evenSubPlot  = size(genAcc_even,1)/(ngroups*ndots);

	H=figure(iMethod);
	set(H,'position', get(0,'ScreenSize'),'color','w');
	for iGroup = 1:2
		switch iGroup
			case 1 % odd
				nSub = oddSubPlot;
				iSub = [1:nSub];
				cGroupGenAcc = genAcc_odd;
			case 2 % even
				nSub = evenSubPlot; % [1:evenSubPlot]+nColm;
				cGroupGenAcc = genAcc_even;
				iSub = [1:nSub 100];
		end

		for iSub = iSub(:)'
			if iSub<100
				iSubGenAcc = cGroupGenAcc([(iSub-1)*(ngroups*ndots)+1:iSub*(ngroups*ndots)],[3 4 5 end]);
				if iGroup ==1
					iSubPlot = iSub;
				else
					iSubPlot = iSub+rowPerSubgroup*nColm;
				end
				subplot(nRow,nColm,iSubPlot);
			else
				subplot(nRow,nColm,nRow*nColm);
% 				[genAccgmCout,genAccgsem,genAccgname,genAccgcout] = grpstats(genAccRaw(:,end-1),{genAccRaw(:,3),genAccRaw(:,4),genAccRaw(:,5)},{'mean','sem','gname','numel'});
				[genAccgm,genAccgSem,genAccgname,genAccgcout]     = grpstats(genAccRaw(genAccRaw(:,5)>0,end),{genAccRaw(genAccRaw(:,5)>0,3),genAccRaw(genAccRaw(:,5)>0,4),genAccRaw(genAccRaw(:,5)>0,5)},{'mean','sem','gname','numel'});
				genAccgname  = cellfun(@str2double,genAccgname);
				iSubGenAcc	 = [genAccgname genAccgm];
			end
			
			iProperty = 0;

			for iConDis = unique(iSubGenAcc(:,1))'
				for iConReg = unique(iSubGenAcc(:,3))'
					iProperty = iProperty+1;
					conFilter = iSubGenAcc(:,1)== iConDis & iSubGenAcc(:,3)== iConReg ;
					cData     = iSubGenAcc(conFilter,end)';
					if iSub<nSub 
						e = plot(x,cData);
					else
						if iSub ==nSub
							genAccgSem = cGroupGenAcc([end-(ngroups*ndots-1):end],[3 4 5 2]);
						end	
						cGenAccgSem = genAccgSem(conFilter,end);
						e           = errorbar(x,cData,cGenAccgSem);
						e.CapSize   = 4;
					end
					hold on; box off;
					e.Color      = lineColor(iProperty,:);
					e.Marker     = marker{iProperty};
					e.MarkerSize = 6;
					e.LineStyle  = lineStyle{iProperty};
					e.LineWidth  = 1;
				end
			end	

			if iSub<nSub
				title(['Sub',num2str(cGroupGenAcc(iSub*ngroups*ndots,2)),'-',figTitle{iMethod}]); 
			elseif iSub ==nSub
				if iGroup ==1
					title('allOddSubMean');
				else
					title('allEvenSubMean');
				end 
			else
				title('allSubMean');
			end
			ylim(genAccRange);
			xlim(xRange);
			set(gca,'xtick',x,'xTickLabel',xTickLabel(x));
		end
	end
	
	print('-depsc','-painters',fullfile(pwd,[num2str(analyBy),'_',num2str(regularGroup),'regulGrp_',figTitle{iMethod},'_',num2str(oddSubPlot+evenSubPlot-2),'.eps']));
% 	saveas(gcf,[analyBy,'_',num2str(regularGroup),'regulGrp_',figTitle{iMethod},'_',num2str(oddSubPlot+evenSubPlot-2),'sub.bmp']);
end

AccForSpss = reshape(genAccRaw(:,7),18,numel(unique(genAccRaw(:,2))))';


% % %%%--------- report exclusions % in paper--------------/
% rowFilter = ~~allSubData(:,14);
% [gm,gsd,gname,corrgcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2)},{'mean','std','gname','numel'});
% mean(corrgcout)/960
% rowFilter = ~~allSubData(:,14)  & allSubData(:,15)<=allSubData(:,16); % allSubData(:,15)>allSubData(:,17) 
% [gm,gsem,gname,smallgcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2)},{'mean','sem','gname','numel'});
% mean(corrgcout-smallgcout)/960
% rowFilter = ~~allSubData(:,14)  & allSubData(:,15)<=allSubData(:,16) & allSubData(:,15)>300; 
% [gm,gsem,gname,biggcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2)},{'mean','sem','gname','numel'});
% mean(smallgcout-biggcout)/960
% rowFilter = ~~allSubData(:,14) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) & allSubData(:,13);
% [gm,gsem,gname,finalgcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,2)},{'mean','sem','gname','numel'});
% mean(gcout-finalgcout)/960
% %%--------- report exclusions % in paper--------------\






% caculate validRt 
% if the 1st predicting trial is wrong, exclude the 2nd predicted trial
rowFilter = ~~allSubData(:,14) & allSubData(:,13) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) ;

[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,1),allSubData(rowFilter,2),allSubData(rowFilter,9),allSubData(rowFilter,3),allSubData(rowFilter,12)},{'mean','sem','gname','numel'});
 gname                = cellfun(@str2double,gname);
 validRt              = [gname,gm,gsem,gcout];
 validRtRaw           = validRt;

 validRt              = validRt(validRt(:,5)>0,:); % only plot regular & paried-non-regular conditions
%-----------allSubMeanRT----------------/
[allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(validRt(:,end),{validRt(:,1),validRt(:,3),validRt(:,4),validRt(:,5)},{'mean','sem','gname','numel'});
[allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(validRt(:,end-2),{validRt(:,1),validRt(:,3),validRt(:,4),validRt(:,5)},{'mean','sem','gname','numel'});
allSubgname = cellfun(@str2double,allSubgname);
validRt([size(validRt,1)+1:size(validRt,1)+size(allSubgname,1)],:) = [allSubgname(:,1),zeros(size(allSubgname,1),1),allSubgname(:,[2:4]),allSubgm,allSubgsem,allSubgmCount]; 
%---------------------------------------\

validRt_odd  = validRt(validRt(:,1)==1,:);
validRt_even = validRt(validRt(:,1)==2,:);
validRtRange = [500,1500];

H=figure(3);
set(H,'position', get(0,'ScreenSize'),'color','w');

%%%%% start to plot validRt %%%%%
for iGroup = 1:2
	switch iGroup
		case 1 % odd
			nSub          = oddSubPlot;
			iSub          = [1:nSub];
			cGroupValidRt = validRt_odd;
			validRtRange  = [400 1200; 600 1400; 700 1500; 600 1400; 600 1400; 600 1400;600 1400;... 
                             200 1000; 700 1500; 800 1600; 400 1200; 600 1400 ; 500 1300];
		case 2 % even
			nSub          = evenSubPlot; % [1:evenSubPlot]+nColm;
			cGroupValidRt = validRt_even;
			iSub          = [1:nSub 100];
			validRtRange  = [700 1500; 400 1200; 800 1600; 400 1200; 600 1400; 600 1400; 500 1300;...
                             400 1200; 600 1400; 600 1400; 400 1200; 800 1600; 600 1400];
	end

	for iSub = iSub(:)'
		if iSub<100
			iSubValidRt    = cGroupValidRt([(iSub-1)*(ngroups*ndots)+1:iSub*(ngroups*ndots)],[3:5,end-2]);
			iSubValidRtSem = cGroupValidRt([(iSub-1)*(ngroups*ndots)+1:iSub*(ngroups*ndots)],[3:5,end-1]);
			if iGroup ==1
				iSubPlot = iSub;
			else
				iSubPlot = iSub+rowPerSubgroup*nColm;
			end
			subplot(nRow,nColm,iSubPlot);
		else
			subplot(nRow,nColm,nRow*nColm);
			% [validRtgmCout,validRtgsem,validRtgname,validRtgcout] = grpstats(validRtRaw(:,end-1),{validRt(:,3),validRt(:,4),validRt(:,5)},{'mean','sem','gname','numel'});
			[validRtgm,validRtgSem,validRtgname,validRtgcout]     = grpstats(validRtRaw(validRtRaw(:,5)>0,end-2),{validRtRaw(validRtRaw(:,5)>0,3),validRtRaw(validRtRaw(:,5)>0,4),validRtRaw(validRtRaw(:,5)>0,5)},{'mean','sem','gname','numel'});
			validRtgname     = cellfun(@str2double,validRtgname);
			iSubValidRt	     = [validRtgname validRtgm];
			iSubValidRtSem	 = [validRtgname validRtgSem];
		end
		
		iProperty = 0;

		for iConDis = unique(iSubValidRt(:,1))'
			for iConReg = unique(iSubValidRt(:,3))'
				iProperty    = iProperty+1;
				conFilter    = iSubValidRt(:,1)== iConDis & iSubValidRt(:,3)== iConReg ;
				cData        = iSubValidRt(conFilter,end)';
				cValidRtgSem = iSubValidRtSem(conFilter,end);
				e            = errorbar(x,cData,cValidRtgSem);
				hold on; box off;
				e.Color      = lineColor(iProperty,:);
				e.Marker     = marker{iProperty};
				e.MarkerSize = 6;
				e.LineStyle  = lineStyle{iProperty};
				e.LineWidth  = 1;
				e.CapSize    = 4;
			end
		end	

		if iSub<nSub
			title(['Sub',num2str(cGroupValidRt(iSub*ngroups*ndots,2)),'-RT']); 
		elseif iSub ==nSub
			if iGroup ==1
				title('allOddSubMean');
			else
				title('allEvenSubMean');
			end 
		else
			title('allSubMean');
		end
		if iSub<100
			ylim(validRtRange(iSub,:));
		else
			ylim([500 1300]);
		end
		xlim(xRange);
		set(gca,'xtick',x,'xTickLabel',xTickLabel(x));
	end
end
print('-depsc','-painters',fullfile(pwd,[num2str(analyBy),'_',num2str(regularGroup),'regulGrp_RT_',num2str(oddSubPlot+evenSubPlot-2),'.eps']));
% saveas(gcf,[analyBy,'_',num2str(regularGroup),'regulGrp_RT_',num2str(oddSubPlot+evenSubPlot-2),'sub.bmp']);

% for spss
RtForSpss = reshape(validRtRaw(:,6),18,numel(unique(validRtRaw(:,2))))';







firstTwoBlockData=allSubData(allSubData(:,4)<=1,:);
rowFilter = ~~firstTwoBlockData(:,14)  & firstTwoBlockData(:,15)>firstTwoBlockData(:,17) & firstTwoBlockData(:,15)<=firstTwoBlockData(:,16) ;

[gm,gsem,gname,gcout] = grpstats(firstTwoBlockData(rowFilter,15),{firstTwoBlockData(rowFilter,1),firstTwoBlockData(rowFilter,2),firstTwoBlockData(rowFilter,9),firstTwoBlockData(rowFilter,12)},{'mean','sem','gname','numel'});
 gname                = cellfun(@str2double,gname);
 validRt              = [gname,gm,gsem,gcout];
 validRtRaw           = validRt;
 RtForSpss = reshape(validRtRaw(:,5),6,numel(unique(validRtRaw(:,2))))';








%%%-----calculate trial-by-trial distance------//

%%%%%%% 一行是一个group，一列是一种bar merge no & low & high
ngroups      = 6;
nbars        = 1;
groupwidth   = min(0.8, nbars/(nbars+1.5));	
for iFig = 1:2
	if iFig==1  % regular trials included 
 		rowFilter = ~~allSubData(:,14) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) ;
 		titleName = 'in';
 	elseif iFig==2  % regular trials excluded  
		rowFilter = allSubData(:,12)~= 1 & ~~allSubData(:,14) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) ;
		titleName = 'ex';		
	end
	[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2),allSubData(rowFilter,30)},{'mean','sem','gname','numel'});
	 gname                = cellfun(@str2double,gname);
	 disRt                = [gname,gm,gsem,gcout];
	[allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(disRt(:,end),{disRt(:,2)},{'mean','sem','gname','numel'}); % ,disRt(:,3)
	[allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(disRt(:,end-2),{disRt(:,2)},{'mean','sem','gname','numel'});
	allSubgname = cellfun(@str2double,allSubgname);
	disRt([size(disRt,1)+1:size(disRt,1)+size(allSubgname,1)],:) = [zeros(size(allSubgname,1),1),allSubgname,allSubgm,allSubgsem,allSubgmCount]; 
	if iFig ==1
		disRtIn = disRt;
	end
	subplot(2,3,iFig);

	% h = bar(disRt([end-ngroups+1:end],3),'grouped','EdgeColor','none');
	h = bar(allSubgm,'grouped','EdgeColor','none');	hold on; 

	hold on; 
	for i = 1:nbars
	    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
	    errorbar(x,allSubgm,allSubgsem,'LineStyle','none','color',[0 0 0],'linewidth',1);
	end	
	ylim([700 1000]);
	box off;
	set(gca,'xTickLabel',{'dis-0','dis-1','dis-2','dis-3','dis-4','none'}) % 'dis-0','dis-1','dis-2','dis-3','dis-4','none'{'noDis','low','high'}
	title(['Exp4--regular trials ', titleName 'cluded']);
end



%%%------ regular pairs are always distance = 4, so consider general other distance=4 trials as baseline 

ngroups      = 2;
nbars        = 1;
groupwidth   = min(0.8, nbars/(nbars+1.5));	
subplot(2,3,3);
rowFilter = ~~allSubData(:,14) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) & allSubData(:,30)==4 ;
[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2),allSubData(rowFilter,12)},{'mean','sem','gname','numel'});
 gname                = cellfun(@str2double,gname);
 disRt                = [gname,gm,gsem,gcout];
[allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(disRt(:,end),{disRt(:,2)},{'mean','sem','gname','numel'});
[allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(disRt(:,end-2),{disRt(:,2)},{'mean','sem','gname','numel'});
allSubgname = cellfun(@str2double,allSubgname);
disRt([size(disRt,1)+1:size(disRt,1)+size(allSubgname,1)],:) = [zeros(size(allSubgname,1),1),allSubgname,allSubgm,allSubgsem,allSubgmCount]; 
h = bar(allSubgm,'grouped','EdgeColor','none');	hold on; 

hold on; 
for i = 1:nbars
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x,allSubgm,allSubgsem,'LineStyle','none','color',[0 0 0],'linewidth',1);
end	
ylim([700 1000]);
box off;
set(gca,'xTickLabel',{'oblique','orth'}) % 'dis-0','dis-1','dis-2','dis-3','dis-4','none'{'noDis','low','high'}
title('distance = 4');


%%%%%%%%%%%%%%%%%%%%%%%%%%  no low high  three conditions %%%%%%%%%%%%%%%%%%%
ngroups      = 3;
nbars        = 6;
groupwidth   = min(0.8, nbars/(nbars+1.5));	
for iFig = 1:2
	if iFig==1  % regular trials included 
 		rowFilter = ~~allSubData(:,14) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) ;
 		titleName = 'in';
 	elseif iFig==2  % regular trials excluded  
		rowFilter = allSubData(:,12)~= 1 & ~~allSubData(:,14) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) ;
		titleName = 'ex';		
	end
	[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2),allSubData(rowFilter,9),allSubData(rowFilter,30)},{'mean','sem','gname','numel'});
	 gname                = cellfun(@str2double,gname);
	 disRt                = [gname,gm,gsem,gcout];
	[allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(disRt(:,end),{disRt(:,2),disRt(:,3)},{'mean','sem','gname','numel'}); % ,disRt(:,3)
	[allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(disRt(:,end-2),{disRt(:,2),disRt(:,3)},{'mean','sem','gname','numel'});
	allSubgname = cellfun(@str2double,allSubgname);
	disRt([size(disRt,1)+1:size(disRt,1)+size(allSubgname,1)],:) = [zeros(size(allSubgname,1),1),allSubgname,allSubgm,allSubgsem,allSubgmCount]; 
	if iFig ==1
		disRtIn = disRt;
	end
	subplot(2,3,iFig+3);

	% h = bar(disRt([end-ngroups+1:end],3),'grouped','EdgeColor','none');
	h = bar(reshape(allSubgm,nbars,ngroups)','grouped','EdgeColor','none');	hold on; 

	hold on; 
	for i = 1:nbars
	    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
	    errorbar(x,allSubgm([0:6:12]+i),allSubgsem([0:6:12]+i),'LineStyle','none','color',[0 0 0],'linewidth',1);
	end	
	ylim([800 1100]);
	box off;
	set(gca,'xTickLabel',{'noDis','low','high'}) % 'dis-0','dis-1','dis-2','dis-3','dis-4','none'
	title(['Exp4--regular trials ', titleName 'cluded']);
end



%%%------ regular pairs are always distance = 4, so consider general other distance=4 trials as baseline 
ngroups      = 3;
nbars        = 2;
groupwidth   = min(0.8, nbars/(nbars+1.5));	
subplot(2,3,6);

rowFilter = ~~allSubData(:,14) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) & allSubData(:,30)==4 & allSubData(:,3)<3;
[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2),allSubData(rowFilter,9),allSubData(rowFilter,12)},{'mean','sem','gname','numel'});
 gname                = cellfun(@str2double,gname);
 disRt                = [gname,gm,gsem,gcout];
[allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(disRt(:,end),{disRt(:,2),disRt(:,3)},{'mean','sem','gname','numel'});
[allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(disRt(:,end-2),{disRt(:,2),disRt(:,3)},{'mean','sem','gname','numel'});
allSubgname = cellfun(@str2double,allSubgname);
disRt([size(disRt,1)+1:size(disRt,1)+size(allSubgname,1)],:) = [zeros(size(allSubgname,1),1),allSubgname,allSubgm,allSubgsem,allSubgmCount]; 
h = bar(reshape(allSubgm,nbars,ngroups)','grouped','EdgeColor','none');	hold on; 

hold on; 
for i = 1:nbars
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x,allSubgm([0:2:4]+i),allSubgsem(([0:2:4]+i)),'LineStyle','none','color',[0 0 0],'linewidth',1);
end	
ylim([700 1000]);
box off;
set(gca,'xTickLabel',{'noDis','low','high'}) % 'dis-0','dis-1','dis-2','dis-3','dis-4','none'{'noDis','low','high'}
title('distance = 4');


%%%%  no difference between locations themselves %%%%

rowFilter = ~~allSubData(:,14) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16);
[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2),allSubData(rowFilter,9),allSubData(rowFilter,12)},{'mean','sem','gname','numel'});
 gname                = cellfun(@str2double,gname);
 disRt                = [gname,gm,gsem,gcout];














%%%%%%%%%%%%%%   collapse all session  %%%%%%%%%%%%
rowFilter = ~~allSubData(:,14) & allSubData(:,13) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) ;

[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,1),allSubData(rowFilter,2),allSubData(rowFilter,9),allSubData(rowFilter,12)},{'mean','sem','gname','numel'});
 gname                = cellfun(@str2double,gname);
 validRt              = [gname,gm,gsem,gcout];
 validRtRaw           = validRt;
 RtForSpss = reshape(validRtRaw(:,5),9,numel(unique(validRtRaw(:,2))))';

% x          = [1:3];
% xRange     = [0.3 3.3];
% xTickLabel = {'pairNonReg','1stDis','1stNoDis'};  % {'S1','S2','S3','S4','S5','S6'}; 

% lineColor  = [255 0 0; 0 0 255 ]/255;
% marker     = {'s','s','*'};
% lineStyle  = {'--','--','--','--'};

% ngroups    = 3; % 
% ndots      = 2;


%%%%% strong supression %%%%%%
pairNonRegul = find(allSubData(:,12)==2 & allSubData(:,5)==1)'; 
for iTrial = pairNonRegul
	if abs(diff(allSubData(iTrial,[6 7])))==4
		allSubData(iTrial+1,22) = 1000; 
	end 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% rowFilter = ~~allSubData(:,14) & allSubData(:,13) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) & allSubData(:,12)>0;
% [gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2),allSubData(rowFilter,5),allSubData(rowFilter,12),allSubData(rowFilter,22)},{'mean','sem','gname','numel'});
%  gname                = cellfun(@str2double,gname);
%  validRt              = [gname,gm,gsem,gcout];
%  validRtRaw           = validRt;
% %-----------allSubMeanRT----------------/
% [allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(validRt(:,end),{validRt(:,2),validRt(:,3),validRt(:,4)},{'mean','sem','gname','numel'});
% [allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(validRt(:,end-2),{validRt(:,2),validRt(:,3),validRt(:,4)},{'mean','sem','gname','numel'});
% allSubgname = cellfun(@str2double,allSubgname);
% validRt([size(validRt,1)+1:size(validRt,1)+size(allSubgname,1)],:) = [zeros(size(allSubgname,1),1),allSubgname,allSubgm,allSubgsem,allSubgmCount]; 





% % %  if switch of color/shape impacted on the learning proces, more/less salince 
% rowFilter = allSubData(:,19)>0 & ~~allSubData(:,14) & allSubData(:,13) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) & allSubData(:,22) ~= 1000;
% [gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2),allSubData(rowFilter,5),allSubData(rowFilter,19),allSubData(rowFilter,12)},{'mean','sem','gname','numel'});
%  gname                = cellfun(@str2double,gname);
%  validRt              = [gname,gm,gsem,gcout];
%  validRtRaw           = validRt;
% %-----------allSubMeanRT----------------/
% [allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(validRt(:,end),{validRt(:,2),validRt(:,3),validRt(:,4)},{'mean','sem','gname','numel'});
% [allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(validRt(:,end-2),{validRt(:,2),validRt(:,3),validRt(:,4)},{'mean','sem','gname','numel'});
% allSubgname = cellfun(@str2double,allSubgname);
% validRt([size(validRt,1)+1:size(validRt,1)+size(allSubgname,1)],:) = [zeros(size(allSubgname,1),1),allSubgname,allSubgm,allSubgsem,allSubgmCount]; 
% %---------------------------------------\
% ngroups      = 4;
% nbars        = 2;
% groupwidth   = min(0.8, nbars/(nbars+1.5));	
% figure;
% for iFig = 1:2
% 	subplot(1,2,iFig);
% 	h = bar(reshape(allSubgm([8*iFig-7:8*iFig]),nbars,ngroups)','grouped','EdgeColor','none');
% 	hold on; 
% 	for i = 1:nbars
% 	    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
% 	    errorbar(x,allSubgm([8*(iFig-1):2:8*iFig-2]+i),allSubgsem([8*(iFig-1):2:8*iFig-2]+i),'LineStyle','none','color',[0 0 0],'linewidth',1);
% 	end	
% 	ylim([800 1200]);
% 	box off;
% 	set(gca,'xTickLabel',{'SrCr','SrCs','SsCr','SsCs'});
% 	if iFig ==1 
% 		title(['Exp3-noDis']);
% 	else
% 		title(['Exp3-Dis']);
% 	end
% end






%%% target-distractor or distractor-distractor influence on learning %%%

distractorTrial = find(allSubData(:,5)==1);
for iDisTrial = distractorTrial'

	%% target-distractor within trial
	TDdis = abs(diff(allSubData(iDisTrial,[6,7])));
	if TDdis<=4
		allSubData(iDisTrial,20) = TDdis;
	else
		allSubData(iDisTrial,20) = 8-TDdis;
	end

	%%% trial-by-trial distractor
	if iDisTrial==1
		allSubData(iDisTrial,21) = 100; % first trial no  
	else
		if isequal(allSubData(iDisTrial,4),allSubData(iDisTrial-1,4)) % the same block
			
			if ~allSubData(iDisTrial-1,5)
				allSubData(iDisTrial,21) = 100; % no
			else
				DDdis = abs(diff(allSubData([iDisTrial-1,iDisTrial],7)));
				if DDdis<=4
					allSubData(iDisTrial,21) = DDdis;
				else
					allSubData(iDisTrial,21) = 8-DDdis;
				end
			end
		end
	end

	% trial-by-trial distractor-target
	if iDisTrial < size(allSubData,1)
		if ~isequal(allSubData(iDisTrial,4),allSubData(iDisTrial+1,4))   % not in the same block
			allSubData(iDisTrial+1,23) = 1000; %
		else
			DTdis = abs(diff([allSubData(iDisTrial,7),allSubData(iDisTrial+1,6)]));
			if DTdis<=4
				allSubData(iDisTrial+1,23) = (DTdis+1)*10;
			else
				allSubData(iDisTrial+1,23) = (8-DTdis+1)*10;
			end
		end
	end
end




%%%%%%%%%%%%%%%%%%%%  target-distractor distance within-trial   %%%%%%%%%%%%%%%%%%%%%% 
rowFilter = allSubData(:,20)>0 &  ~~allSubData(:,14)  & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) & allSubData(:,9)==2  % & allSubData(:,22)~=1000 allSubData(:,12)>0
[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2), allSubData(rowFilter,20),allSubData(rowFilter,12)},{'mean','sem','gname','numel'});
 gname                = cellfun(@str2double,gname);
 validRt              = [gname,gm,gsem,gcout];
%-----------allSubMeanRT----------------/
[allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(validRt(:,end),{validRt(:,2),validRt(:,3)},{'mean','sem','gname','numel'});
[allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(validRt(:,end-2),{validRt(:,2),validRt(:,3)},{'mean','sem','gname','numel'});
allSubgname = cellfun(@str2double,allSubgname);
validRt([size(validRt,1)+1:size(validRt,1)+size(allSubgname,1)],:) = [zeros(size(allSubgname,1),1), allSubgname, allSubgm,allSubgsem,allSubgmCount]; 
%---------------------------------------\
ngroups      = 4;
nbars        = 2;
groupwidth   = min(0.8, nbars/(nbars+1.5));	
figure;
h = bar(reshape(allSubgm,nbars,ngroups)','grouped','EdgeColor','none');
hold on; 
for i = 1:nbars
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x,allSubgm([0:2:6]+i),allSubgsem([0:2:6]+i),'LineStyle','none','color',[0 0 0],'linewidth',1);
end	
ylim([800 1200]);
box off;
set(gca,'xTickLabel',{'dis-1','dis-2','dis-3','dis-4'})
title(['Exp3-tarDistraDistance']);




% % trial-by-trial distractor-target distance no effect
% rowFilter =  ~~allSubData(:,14)  & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) ;
% [gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2),allSubData(rowFilter,5),allSubData(rowFilter,23)},{'mean','sem','gname','numel'});
%  gname                = cellfun(@str2double,gname);
%  validRt              = [gname,gm,gsem,gcout];
% %-----------allSubMeanRT----------------/
% [allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(validRt(:,end),{validRt(:,2),validRt(:,3)},{'mean','sem','gname','numel'});
% [allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(validRt(:,end-2),{validRt(:,2),validRt(:,3)},{'mean','sem','gname','numel'});
% allSubgname = cellfun(@str2double,allSubgname);
% validRt([size(validRt,1)+1:size(validRt,1)+size(allSubgname,1)],:) = [zeros(size(allSubgname,1),1), allSubgname, allSubgm,allSubgsem,allSubgmCount]; 
% %---------------------------------------\
% ngroups      = 6;
% nbars        = 1;
% groupwidth   = min(0.8, nbars/(nbars+1.5));	
% figure;
% h = bar(reshape(allSubgm,nbars,ngroups)','grouped','EdgeColor','none');
% hold on; 
% for i = 1:nbars
%     x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
%     errorbar(x,allSubgm,allSubgsem,'LineStyle','none','color',[0 0 0],'linewidth',1);
% end	
% ylim([800 1200]);
% box off;
% set(gca,'xTickLabel',{'dis-0','dis-1','dis-2','dis-3','dis-4','none'})
% title(['Exp3-TrialDistracDistance']);





% % trial-by-trial distractor distance
% rowFilter =  ~~allSubData(:,14)  & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) ;
% [gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2),allSubData(rowFilter,21)},{'mean','sem','gname','numel'});
%  gname                = cellfun(@str2double,gname);
%  validRt              = [gname,gm,gsem,gcout];
% %-----------allSubMeanRT----------------/
% [allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(validRt(:,end),{validRt(:,2)},{'mean','sem','gname','numel'});
% [allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(validRt(:,end-2),{validRt(:,2)},{'mean','sem','gname','numel'});
% allSubgname = cellfun(@str2double,allSubgname);
% validRt([size(validRt,1)+1:size(validRt,1)+size(allSubgname,1)],:) = [zeros(size(allSubgname,1),1), allSubgname, allSubgm,allSubgsem,allSubgmCount]; 
% %---------------------------------------\
% ngroups      = 6;
% nbars        = 1;
% groupwidth   = min(0.8, nbars/(nbars+1.5));	
% figure;
% h = bar(reshape(allSubgm,nbars,ngroups)','grouped','EdgeColor','none');
% hold on; 
% for i = 1:nbars
%     x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
%     errorbar(x,allSubgm,allSubgsem,'LineStyle','none','color',[0 0 0],'linewidth',1);
% end	
% ylim([800 1200]);
% box off;
% set(gca,'xTickLabel',{'dis-0','dis-1','dis-2','dis-3','dis-4','none'})
% title(['Exp3-TrialDistracDistance']);





% % trial-by-trial distractor distance: regular and nonregular
% rowFilter =  allSubData(:,5)>0 & allSubData(:,12)>0 & ~~allSubData(:,14)  & allSubData(:,13) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16) ;
% [gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,2),allSubData(rowFilter,21),allSubData(rowFilter,12)},{'mean','sem','gname','numel'});
%  gname                = cellfun(@str2double,gname);
%  validRt              = [gname,gm,gsem,gcout];
% %-----------allSubMeanRT----------------/
% [allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(validRt(:,end),{validRt(:,2),validRt(:,3)},{'mean','sem','gname','numel'});
% [allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(validRt(:,end-2),{validRt(:,2),validRt(:,3)},{'mean','sem','gname','numel'});
% allSubgname = cellfun(@str2double,allSubgname);
% validRt([size(validRt,1)+1:size(validRt,1)+size(allSubgname,1)],:) = [zeros(size(allSubgname,1),1), allSubgname, allSubgm,allSubgsem,allSubgmCount]; 
% %---------------------------------------\
% ngroups      = 6;
% nbars        = 2;
% groupwidth   = min(0.8, nbars/(nbars+1.5));	
% figure;
% h = bar(reshape(allSubgm,nbars,ngroups)','grouped','EdgeColor','none');
% hold on; 
% for i = 1:nbars
%     x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
%     errorbar(x,allSubgm([0:2:10]+i),allSubgsem([0:2:10]+i),'LineStyle','none','color',[0 0 0],'linewidth',1);
% end	
% ylim([800 1200]);
% box off;
% set(gca,'xTickLabel',{'dis-0','dis-1','dis-2','dis-3','dis-4','none'})
% title(['Exp3-TrialDistracDistance']);
















% %%%   pretrial is with or without distractor
% rowFilter =  allSubData(:,12)>0 & ~~allSubData(:,14) & allSubData(:,13) & allSubData(:,15)>allSubData(:,17) & allSubData(:,15)<=allSubData(:,16);
% [gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,15),{allSubData(rowFilter,1),allSubData(rowFilter,2),allSubData(rowFilter,5),allSubData(rowFilter,18)},{'mean','sem','gname','numel'});
%  gname                = cellfun(@str2double,gname);
% preDisRt              = [gname,gm,gsem,gcout];
% preDisRtRaw           = preDisRt;
% %-----------allSubMeanRT----------------/
% [allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(preDisRt(:,end),{preDisRt(:,1),preDisRt(:,3),preDisRt(:,4)},{'mean','sem','gname','numel'});
% [allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(preDisRt(:,end-2),{preDisRt(:,1),preDisRt(:,3),preDisRt(:,4)},{'mean','sem','gname','numel'});
% allSubgname = cellfun(@str2double,allSubgname);
% preDisRt([size(preDisRt,1)+1:size(preDisRt,1)+size(allSubgname,1)],:) = [allSubgname(:,1),zeros(size(allSubgname,1),1) allSubgname(:,[2:3]), allSubgm,allSubgsem,allSubgmCount]; 
% %---------------------------------------\

% preDisRt_odd  = preDisRt(preDisRt(:,1)==1,:);
% preDisRt_even = preDisRt(preDisRt(:,1)==2,:);

% H=figure;
% set(H,'position', get(0,'ScreenSize'),'color','w');

% %%%%% start to plot preDisRt %%%%%
% for iGroup = 1:2
% 	switch iGroup
% 		case 1 % odd
% 			nSub          = 13;
% 			iSub          = [1:nSub];
% 			cGrouppreDisRt = preDisRt_odd;
% 			preDisRtRange  = [750 1150; 1100 1500; 700 1100; 800 1200; 1000 1400; 800 1200;800 1200;... 
%                              900 1300; 700 1100; 1100 1500; 900 1300;  800 1200 ;900 1300];
% 		case 2 % even
% 			nSub          = 12; % [1:evenSubPlot]+nColm;
% 			cGrouppreDisRt = preDisRt_even;
% 			iSub          = [1:nSub 100];
% 			preDisRtRange  = [500 900; 500 900; 1100 1500; 750 1150; 700 1100; 500 900; 700 1100;...
%                              500 900; 500 900; 800 1200;  1000 1400; 700 1100; 800 1200];
% 	end

% 	for iSub = iSub(:)'
% 		if iSub<100
% 			iSubpreDisRt    = cGrouppreDisRt([(iSub-1)*(ngroups*ndots)+1:iSub*(ngroups*ndots)],[3:5,end-2]);
% 			iSubpreDisRtSem = cGrouppreDisRt([(iSub-1)*(ngroups*ndots)+1:iSub*(ngroups*ndots)],[3:5,end-1]);
% 			if iGroup ==1
% 				iSubPlot = iSub;
% 			else
% 				iSubPlot = iSub+rowPerSubgroup*nColm;
% 			end
% 			subplot(nRow,nColm,iSubPlot);
% 		else
% 			subplot(nRow,nColm,nRow*nColm);
% 			% [preDisRtgmCout,preDisRtgsem,preDisRtgname,preDisRtgcout] = grpstats(preDisRtRaw(:,end-1),{preDisRt(:,3),preDisRt(:,4),preDisRt(:,5)},{'mean','sem','gname','numel'});
% 			[preDisRtgm,preDisRtgSem,preDisRtgname,preDisRtgcout]     = grpstats(preDisRtRaw(:,end-2),{preDisRtRaw(:,3),preDisRtRaw(:,4)},{'mean','sem','gname','numel'});
% 			preDisRtgname   = cellfun(@str2double,preDisRtgname);
% 			iSubpreDisRt    = [preDisRtgname preDisRtgm];
% 			iSubpreDisRtSem = [preDisRtgname preDisRtgSem];
% 		end
		
% 		iProperty = 0;

% 		for iConDis = unique(iSubpreDisRt(:,1))'
% 			% for iConReg = unique(iSubpreDisRt(:,3))'
% 				iProperty    = iProperty+1;
% 				conFilter    = iSubpreDisRt(:,1)== iConDis; % & iSubpreDisRt(:,3)== iConReg ;
% 				cData        = iSubpreDisRt(conFilter,end)';
% 				cpreDisRtgSem = iSubpreDisRtSem(conFilter,end);
% 				e            = errorbar(x,cData,cpreDisRtgSem);
% 				hold on; box off;
% 				e.Color      = lineColor(iProperty,:);
% 				e.Marker     = marker{iProperty};
% 				e.MarkerSize = 6;
% 				e.LineStyle  = lineStyle{iProperty};
% 				e.LineWidth  = 0.7;
% 				e.CapSize    = 4;
% 			% end
% 		end	

% 		if iSub<nSub
% 			title(['Sub',num2str(cGrouppreDisRt(iSub*ngroups*ndots,2)),'-RT']); 
% 		elseif iSub ==nSub
% 			if iGroup ==1
% 				title('allOddSubMean');
% 			else
% 				title('allEvenSubMean');
% 			end 
% 		else
% 			title('allSubMean');
% 		end
% 		if iSub<100
% 			ylim(preDisRtRange(iSub,:));
% 		else
% 			ylim(preDisRtRange(end,:));
% 		end
% 		xlim(xRange);
% 		set(gca,'xtick',x,'xTickLabel',xTickLabel(x));
% 	end
% end
% print('-depsc','-painters','noBlock_4con.eps');
% % saveas(gcf,[analyBy,'_',num2str(regularGroup),'regulGrp_RT_',num2str(oddSubPlot+evenSubPlot-2),'sub.bmp']);

% % for spss
% RtForSpss_4con = reshape(preDisRtRaw(:,5),ndots*ngroups,numel(unique(preDisRtRaw(:,2))))';


% reshape(preDisRt([1:end-size(allSubgname,1)],5),size(allSubgname,1),23)







cd ..
% close all;
save(['result_gray_distractor_',num2str(8/analyBy),'sess_',num2str(randLocGroupNum),'rdmGrp']);





