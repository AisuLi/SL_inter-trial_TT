function behAnaly_SL(directory)

% add succesive sessions training trend 

if ~exist('directory','var') || isempty(directory) 
	if ~ispc
		directory = '/Volumes/LASBK/weekendJob/AnalyData/control';
	else
		addpath('H:\Desktop\mytoolbox');
		savepath;
		directory = 'H:\Desktop\expData\SL_horVer_20181008\Exp1_20181028\Data\AnalyData\exp2_noDisCtrl';
	end
end

cd(directory);

allfiles     = dir(fullfile(pwd,'*.mat'));
allSubData   = [];
allSubRepeat = [];
allSubDataInfo = {'oddEven';'subNo';'sessionNo';'blockNo';'targLoc';'targShape';
					'targColor';'targLine';'regular';'regularPairedAcc';'acc';'rt'};

allSubRepeatInfo = {'targetRepeat','distraRepeat','shapeRepeat','colorRepeat'};
analyByBlock     = 1; % 'halfSession'
regularGroup     = 2; % 2=random+regular; 3=random+horizontal+vertical;
randLocGroupNum  = 2; % 1= nonPair+pairNonReg

for iMat = 1:size(allfiles,1)
	cFile = allfiles(iMat).name;
	load(cFile);
	cSubData     = [];
	cSubRepeat   = [];
	cSubTrialDis = [];

	for iBlock = 1:size(designMatrix,3)
		cBlockData   = [repmat(iBlock,size(designMatrix,1),1) squeeze(designMatrix(:,[1:end-1],iBlock))];
		cSubData     = [cSubData;cBlockData];

		% cBlockRepeat = [];
		% for iTrial = 2:size(cBlockData,1)
		% 	if cBlockData(iTrial,3) == cBlockData(iTrial-1,3)
		% 		cBlockRepeat(iTrial,1) = 1;
		% 	elseif cBlockData(iTrial,4) == cBlockData(iTrial-1,4)
		% 		if cBlockData(iTrial,3)~=0
		% 			cBlockRepeat(iTrial,2) = 1;
		% 		end
		% 	elseif cBlockData(iTrial,5) == cBlockData(iTrial-1,5)
		% 			cBlockRepeat(iTrial,3) = 1;
		% 	elseif cBlockData(iTrial,6) == cBlockData(iTrial-1,6)
		% 			cBlockRepeat(iTrial,4) = 1;			
		% 	end  
		% end
		% cSubRepeat   = [cSubRepeat;cBlockRepeat];  


		for iTrial = 1:size(cBlockData,1)
			if iTrial == 1 % first trial no preTrial
				cSubTrialDis(iTrial,iBlock) = 100; 
			else % nonFirst Trial
				if ~acc(iTrial-1,iBlock) % no relationship with wrong preTrial
					cSubTrialDis(iTrial,iBlock) = 100; 
				else 
					cLoc = cBlockData([iTrial-1,iTrial],2) ;
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
	end % iBlock
	% a = sum(cSubRepeat,1);
	% fprintf('%d\n',a);
	cSubData = [repmat([2-mod(str2num(subInfo{1}),2) str2num(subInfo{1}) str2num(subInfo{2})],size(cSubData,1),1) cSubData];
	
	% if mod(str2num(subInfo{1}),2)
	% 	cSubData(cSubData(:,5)==8,9) = 1; % before: 1 2 3 4
	% 	cSubData(cSubData(:,5)==6,9) = regularGroup-1;
	% else
	% 	cSubData(cSubData(:,5)==4,9) = 1;
	% 	cSubData(cSubData(:,5)==2,9) = regularGroup-1;
	% end
	cSubData(:,[10:12]) = [ones(size(cSubData,1),1) acc(:) responseTimes(:)*1000];
	cSubData(:,15)      = cSubTrialDis(:);
	allSubData          = [allSubData;cSubData];
	% allSubRepeat        = [allSubRepeat;cSubRepeat];
end

allSubData(:,3)                 = ceil(allSubData(:,4)/analyByBlock);


if regularGroup==2
	if randLocGroupNum==2
		regularTrialPerBlock = [32 16 16]; % nonPair, regular, pair-nonRegular
	else
		regularTrialPerBlock = [48 16];
	end
% elseif regularGroup==3
% 	regularTrialPerBlock = [18 3 3;42 7 7];
end

regulTrialNum  = repmat(analyByBlock*regularTrialPerBlock',numel(unique(allSubData(:,3))),1);

switch analyByBlock
	case 4 % 4blocks
		x              = [1:2];
		xRange         = [0.3 2.3];
		nRow           = 4;
		rowPerSubgroup = 2; 
		nColm 		   = 6;
	case 2 % 2blocks
		x              = [1:4];
		xRange         = [0.3 4.3];
		nRow  		   = 4;
		rowPerSubgroup = 2; 
		nColm 		   = 6;
    case 1 % 1block
        x              = [1:8];
        xRange         = [0.3 8.3];
        nRow           = 4;
        rowPerSubgroup = 2; 
        nColm 		   = 7;
end


%  0 = random locations, 2 = specific predicting, 1 = specific predicted  / same in random session1
for i =1:size(allSubData,1)
	if mod(allSubData(i,5),2) % target = 1 3 5 7
		allSubData(i,9)=0;
	else % target at 2,4,6,8
		if mod(allSubData(i,2),2)==1 % odd subject: 2→6, 4→8
			if ismember(allSubData(i,5),[6 8])
				allSubData(i,9)=1;
			else
				if randLocGroupNum==2
					allSubData(i,9)=2;
				else
					allSubData(i,9)=0;
				end
			end
		else % even subject
			if ismember(allSubData(i,5),[6 8])
				if randLocGroupNum==2
					allSubData(i,9)=2;
				else
					allSubData(i,9)=0;
				end
			else
				allSubData(i,9)=1;
			end
		end
	end
end


%% regularity included in block 5~8
regulFilter = allSubData(:,4)>4 & allSubData(:,9)==1;
regulTrial  = find(regulFilter==1);
for iRegulTrial = regulTrial'

	% predicted trials: relationship with preTrial regarding color and shape 
	if isequal(allSubData(iRegulTrial,6),allSubData(iRegulTrial-1,6)) % repeat shape 
		if isequal(allSubData(iRegulTrial,7),allSubData(iRegulTrial-1,7))
			allSubData(iRegulTrial,17) = 1; % repeat color 
		else
			allSubData(iRegulTrial,17) = 2; 
		end
	else % switch shape
		if isequal(allSubData(iRegulTrial,7),allSubData(iRegulTrial-1,7))
			allSubData(iRegulTrial,17) = 3; 
		else
			allSubData(iRegulTrial,17) = 4; 
		end
	end
		

	% predicting trials: relationship with preTrial regarding color and shape 
	if isequal(allSubData(iRegulTrial-1,4),allSubData(iRegulTrial-2,4)) % have to be in the same block
		% predicting
		if isequal(allSubData(iRegulTrial-1,6),allSubData(iRegulTrial-2,6)) % repeat shape 
			if isequal(allSubData(iRegulTrial-1,7),allSubData(iRegulTrial-2,7))
				allSubData(iRegulTrial-1,17) = 1; % repeat color 
			else
				allSubData(iRegulTrial-1,17) = 2; 
			end
		else % switch shape
			if isequal(allSubData(iRegulTrial-1,7),allSubData(iRegulTrial-2,7))
				allSubData(iRegulTrial-1,17) = 3; 
			else
				allSubData(iRegulTrial-1,17) = 4; 
			end
		end
	end
	allSubData(iRegulTrial,10) = allSubData(iRegulTrial-1,11);
end


%%% restrict trial-by-trial distance = 4-item %%%
dis4Trial = find(allSubData(:,15)==4);
for idis4Trial = dis4Trial'
	allSubData(idis4Trial,16) = 2-mod(allSubData(idis4Trial,5),2); %% 1=oblique 2=ortho
end


% % report overall accuracy 
% [gm,gsd,gname,corrgcout] = grpstats(allSubData(:,11),{allSubData(:,2)},{'mean','std','gname','numel'});
% mean(gm);


		
%%% cutoff outliers 
rowFilter = ~~allSubData(:,11);
[gm,gsd,gname,corrgcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,2),allSubData(rowFilter,4)},{'mean','std','gname','numel'});
 gname                   = cellfun(@str2double,gname);
[zscores]                = shiftzs_BCL([corrgcout],0); 

for iRow = 1:size(gname,1)
   
   conFilter = allSubData(:,2) == gname(iRow,1) & allSubData(:,4) == gname(iRow,2) ;
   
   allSubData(conFilter,13) = gm(iRow) + zscores(iRow)*gsd(iRow);  % zscores(iRow)
   allSubData(conFilter,14) = 200;
end


figTitle   = {'genAcc','realAcc'};
xTickLabel = {'S1','S2','S3','S4','S5','S6','S7','S8'}; 

if regularGroup==3
	lineColor    = [255 0 0; 255 0 0;255 0 0;0 0 255; 0 0 255; 0 0 255]/255;
	marker       = {'s','o','*','s','o','*'};
	lineStyle    = {'--','--','--','--','--','--'};
elseif regularGroup==2
	lineColor    = [255 0 0; 255 0 0;0 0 255]/255;
	marker       = {'s','o','o','s'};
	lineStyle    = {'--','--','--','--'};
end

for iMethod = 1:2
	if iMethod==1 %% general ACC of regular & non-regular 
		
		rowFilter                = ~~allSubData(:,11); % genearal ACC
		[gm,gsd,gname,corrgcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,1),allSubData(rowFilter,2),allSubData(rowFilter,3),allSubData(rowFilter,9)},{'mean','std','gname','numel'});
		gname                    = cellfun(@str2double,gname);
		genAcc                   = [gname,corrgcout];
		genAcc(:,end+1)          = genAcc(:,end)./repmat(regulTrialNum,numel(unique(allSubData(:,2))),1);

	elseif iMethod==2 %%%  another Acc minus wrong predicting trials
		
		rowFilter                = ~~allSubData(:,10);
		[gm,gsd,gname,realgcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,1),allSubData(rowFilter,2),allSubData(rowFilter,3),allSubData(rowFilter,9)},{'mean','std','gname','numel'});
		rowFilter                = ~~allSubData(:,11) & allSubData(:,10); 
		[gm,gsd,gname,corrgcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,1),allSubData(rowFilter,2),allSubData(rowFilter,3),allSubData(rowFilter,9)},{'mean','std','gname','numel'});

		gname                    = cellfun(@str2double,gname);
		genAcc                   = [gname,corrgcout];
		genAcc(:,end+1)          = genAcc(:,end)./realgcout;
	end

	genAccRaw = genAcc;
	[genAccgmCout,genAccgsem,genAccgname,genAccgcout] = grpstats(genAcc(:,end-1),{genAcc(:,1),genAcc(:,3),genAcc(:,4)},{'mean','sem','gname','numel'});
	[genAccgm,genAccgsem,genAccgname,genAccgcout]     = grpstats(genAcc(:,end),{genAcc(:,1),genAcc(:,3),genAcc(:,4)},{'mean','sem','gname','numel'});
	genAccgname  = cellfun(@str2double,genAccgname);
	genAcc([size(genAcc,1)+1:size(genAcc,1)+size(genAccgname,1)],:) = [genAccgname(:,1),genAccgsem,genAccgname(:,[2:3]),genAccgmCout genAccgm]; 
	genAcc_odd  = genAcc(genAcc(:,1)==1,:);
	genAcc_even = genAcc(genAcc(:,1)==2,:);

	%%%%% start to plot genAcc %%%%%
	genAccRange  = [0.7,1];
	ngroups      = numel(regularTrialPerBlock);
	ndots        = numel(unique(genAcc(:,3)));   
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
				iSubGenAcc = cGroupGenAcc([(iSub-1)*(ngroups*ndots)+1:iSub*(ngroups*ndots)],[3 4 end]);
				if iGroup ==1
					iSubPlot = iSub;
				else
					iSubPlot = iSub+rowPerSubgroup*nColm;
				end
				subplot(nRow,nColm,iSubPlot);
			else
				subplot(nRow,nColm,nRow*nColm);
% 				[genAccgmCout,genAccgsem,genAccgname,genAccgcout] = grpstats(genAccRaw(:,end-1),{genAccRaw(:,3),genAccRaw(:,4),genAccRaw(:,5)},{'mean','sem','gname','numel'});
				[genAccgm,genAccgSem,genAccgname,genAccgcout]     = grpstats(genAccRaw(:,end),{genAccRaw(:,3),genAccRaw(:,4)},{'mean','sem','gname','numel'});
				genAccgname  = cellfun(@str2double,genAccgname);
				iSubGenAcc	 = [genAccgname genAccgm];
			end
			

			for iConReg = unique(iSubGenAcc(:,2))'
				
				conFilter = iSubGenAcc(:,2) == iConReg ;
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
				e.Color      = lineColor(iConReg+1,:);
				e.Marker     = marker{iConReg+1};
				e.MarkerSize = 6;
				e.LineStyle  = lineStyle{iConReg+1};
				e.LineWidth  = 1;
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
	print('-depsc','-painters',fullfile(pwd,[num2str(analyByBlock),'_',num2str(regularGroup),'regulGrp_',figTitle{iMethod},'_',num2str(oddSubPlot+evenSubPlot-2),'.eps']));
% 	saveas(gcf,[analyByBlock,'_',num2str(regularGroup),'regulGrp_',figTitle{iMethod},'_',num2str(oddSubPlot+evenSubPlot-2),'sub.bmp']);
end

AccForSpss = reshape(genAccRaw(:,6),ndots*ngroups,numel(unique(genAccRaw(:,2))))';
genAccRaw(genAccRaw(:,3)>4,7)=1;
[meanOfBlock,genAccgsem,genAccgname,genAccgcout] = grpstats(genAccRaw(:,6),{genAccRaw(:,1),genAccRaw(:,2),genAccRaw(:,7),genAccRaw(:,4)},{'mean','sem','gname','numel'});
AccMeanForSpss = reshape(meanOfBlock,6,numel(unique(genAccRaw(:,2))))';


% %%%--------- report exclusions % in paper--------------/
% rowFilter = ~~allSubData(:,11);
% [gm,gsd,gname,corrgcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,2)},{'mean','std','gname','numel'});
% rowFilter = ~~allSubData(:,11) & allSubData(:,12)>allSubData(:,14) & allSubData(:,12)<=allSubData(:,13);
% [gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,2)},{'mean','sem','gname','numel'});
% mean(corrgcout-gcout)/512;
% rowFilter = ~~allSubData(:,11) & allSubData(:,12)>allSubData(:,14) & allSubData(:,12)<=allSubData(:,13) & allSubData(:,10);
% [gm,gsem,gname,finalgcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,2)},{'mean','sem','gname','numel'});
% mean(gcout-finalgcout)/512;
% %%%--------- report exclusions % in paper--------------\


%%%%%%%%%%%%%%%%% calculate trial-by-trial distance %%%%%%%%%%%%%%%%%%%%


% % %%------session 1 is random------
rowFilter = allSubData(:,4)<5 & ~~allSubData(:,11) & allSubData(:,12)>allSubData(:,14) & allSubData(:,12)<=allSubData(:,13);

% %%------session 2 is regular-----
ngroups      = 6;
nbars        = 1;
groupwidth   = min(0.8, nbars/(nbars+1.5));	
for iFig = 1:2
	if iFig==1  % regular trials included 
		rowFilter = allSubData(:,4)>4 & ~~allSubData(:,11) & allSubData(:,12)>allSubData(:,14) & allSubData(:,12)<=allSubData(:,13);
 		titleName = 'in';
 	elseif iFig==2  % regular trials excluded  
		rowFilter = allSubData(:,9)~= 1 & allSubData(:,4)>4 & ~~allSubData(:,11) & allSubData(:,12)>allSubData(:,14) & allSubData(:,12)<=allSubData(:,13);
		titleName = 'ex';		
	end
	[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,2),allSubData(rowFilter,15)},{'mean','sem','gname','numel'});
	 gname                = cellfun(@str2double,gname);
	 disRt                = [gname,gm,gsem,gcout];
	[allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(disRt(:,end),{disRt(:,2)},{'mean','sem','gname','numel'});
	[allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(disRt(:,end-2),{disRt(:,2)},{'mean','sem','gname','numel'});
	allSubgname = cellfun(@str2double,allSubgname);
	disRt([size(disRt,1)+1:size(disRt,1)+size(allSubgname,1)],:) = [zeros(size(allSubgname,1),1),allSubgname,allSubgm,allSubgsem,allSubgmCount]; 
	if iFig ==1
		disRtIn = disRt;
	end
	% subplot(2,3,4);
	subplot(2,3,iFig+4);
	h = bar(disRt([end-5:end],3),'grouped','EdgeColor','none');
	hold on; 
	for i = 1:nbars
	    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
	    errorbar(x,allSubgm,allSubgsem,'LineStyle','none','color',[0 0 0],'linewidth',1);
	end	
	ylim([700 1000]);
	box off;
	set(gca,'xTickLabel',{'dis-0','dis-1','dis-2','dis-3','dis-4','none'});
	% title('Exp2--random');
	title(['Exp2--regular trials ', titleName 'cluded']);
end
%%-----------------------------------------------------------------


% %%%%%%%%%%  regular pairs are always distance = 4, so consider  %%%%%%%%%%
%%%%%%%%%%    general other distance=4 trials as baseline       %%%%%%%%%%

%% sess1 rdm, compare oblique and orthg
rowFilter = allSubData(:,4)<5 & ~~allSubData(:,11) & allSubData(:,12)>allSubData(:,14) & allSubData(:,12)<=allSubData(:,13) & allSubData(:,16)>0;  %% 16： 1=oblique 2=ortho 

%% sess2 regular, compare oblique(non-regular) and orthg(regular)
rowFilter = allSubData(:,4)>4 & ~~allSubData(:,11) & allSubData(:,12)>allSubData(:,14) & allSubData(:,12)<=allSubData(:,13) & allSubData(:,16)>0;

[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,2),allSubData(rowFilter,16)},{'mean','sem','gname','numel'});
 gname                = cellfun(@str2double,gname);
 disRt                = [gname,gm,gsem,gcout];
[allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(disRt(:,end),{disRt(:,2)},{'mean','sem','gname','numel'});
[allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(disRt(:,end-2),{disRt(:,2)},{'mean','sem','gname','numel'});
allSubgname = cellfun(@str2double,allSubgname);
disRt([size(disRt,1)+1:size(disRt,1)+size(allSubgname,1)],:) = [zeros(size(allSubgname,1),1),allSubgname,allSubgm,allSubgsem,allSubgmCount]; 

%%%------- switch of color/shape -------
% rowFilter = ~~allSubData(:,11) & allSubData(:,10) & allSubData(:,12)>allSubData(:,14) & allSubData(:,12)<=allSubData(:,13) & allSubData(:,17)>0;
% [gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,2),allSubData(rowFilter,17),allSubData(rowFilter,9)},{'mean','sem','gname','numel'});
%  gname                = cellfun(@str2double,gname);
%  switchRt             = [gname,gm,gsem,gcout];
% [allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(switchRt(:,end),{switchRt(:,2),switchRt(:,3)},{'mean','sem','gname','numel'});
% [allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(switchRt(:,end-2),{switchRt(:,2),switchRt(:,3)},{'mean','sem','gname','numel'});
% allSubgname = cellfun(@str2double,allSubgname);
% switchRt([size(switchRt,1)+1:size(switchRt,1)+size(allSubgname,1)],:) = [zeros(size(allSubgname,1),1),allSubgname,allSubgm,allSubgsem,allSubgmCount]; 
% reshape(switchRt([1:end-size(allSubgname,1)],4),size(allSubgname,1),24)'

% %%%%-----------------------------------------------------------------\\




% caculate validRt 
% if the 1st predicting trial is wrong, exclude the 2nd predicted trial
rowFilter = ~~allSubData(:,11) & allSubData(:,12)>allSubData(:,14) & allSubData(:,12)<=allSubData(:,13);  %  allSubData(:,10) &


[gm,gsem,gname,gcout] = grpstats(allSubData(rowFilter,12),{allSubData(rowFilter,1),allSubData(rowFilter,2),allSubData(rowFilter,40),allSubData(rowFilter,9)},{'mean','sem','gname','numel'});
 gname                = cellfun(@str2double,gname);
 validRt              = [gname,gm,gsem,gcout];
 validRtRaw           = validRt;

%-----------allSubMeanRT----------------/
[allSubgmCount,allSubgsem,allSubgname,allSubcorrgcout] = grpstats(validRt(:,end),{validRt(:,1),validRt(:,3),validRt(:,4)},{'mean','sem','gname','numel'});
[allSubgm,allSubgsem,allSubgname,allSubcorrgcout]      = grpstats(validRt(:,end-2),{validRt(:,1),validRt(:,3),validRt(:,4)},{'mean','sem','gname','numel'});
allSubgname = cellfun(@str2double,allSubgname);
validRt([size(validRt,1)+1:size(validRt,1)+size(allSubgname,1)],:) = [allSubgname(:,1),zeros(size(allSubgname,1),1),allSubgname(:,[2:3]),allSubgm,allSubgsem,allSubgmCount]; 
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
			validRtRange  = [500 1000;  700 1200; 500 1000; 700 1200;650 1150;650 1150;500 1000;...
							 400 900;   400 900;  700 1200; 800 1300; 600 1100;600 1100];
		case 2 % even
			nSub          = evenSubPlot; % [1:evenSubPlot]+nColm;
			cGroupValidRt = validRt_even;
			iSub          = [1:nSub 100];
			validRtRange  = [600 1100;600 1100;500 1000;600 1100;850 1350;600 1100; 700 1200; 
						     700 1200;600 1100;500 1000;600 1100; 400 900;600 1100];
	end

	for iSub = iSub(:)'
		if iSub<100
			iSubValidRt    = cGroupValidRt([(iSub-1)*(ngroups*ndots)+1:iSub*(ngroups*ndots)],[3:4,end-2]);
			iSubValidRtSem = cGroupValidRt([(iSub-1)*(ngroups*ndots)+1:iSub*(ngroups*ndots)],[3:4,end-1]);
			if iGroup ==1
				iSubPlot = iSub;
			else
				iSubPlot = iSub+rowPerSubgroup*nColm;
			end
			subplot(nRow,nColm,iSubPlot);
		else
			subplot(nRow,nColm,nRow*nColm);
			[validRtgmCout,validRtgsem,validRtgname,validRtgcout] = grpstats(validRtRaw(:,end-1),{validRt(:,3),validRt(:,4),validRt(:,5)},{'mean','sem','gname','numel'});
			[validRtgm,validRtgSem,validRtgname,validRtgcout]     = grpstats(validRtRaw(:,end-2),{validRtRaw(:,3),validRtRaw(:,4)},{'mean','sem','gname','numel'});
			validRtgname     = cellfun(@str2double,validRtgname);
			iSubValidRt	     = [validRtgname validRtgm];
			iSubValidRtSem	 = [validRtgname validRtgSem];
		end
		

		for iConReg = unique(iSubValidRt(:,2))'
			conFilter    = iSubValidRt(:,2)== iConReg;
			cData        = iSubValidRt(conFilter,end)';
			cValidRtgSem = iSubValidRtSem(conFilter,end);
			e            = errorbar(x,cData,cValidRtgSem);
			hold on; box off;
			e.Color      = lineColor(iConReg+1,:);
			e.Marker     = marker{iConReg+1};
			e.MarkerSize = 6;
			e.LineStyle  = lineStyle{iConReg+1};
			e.LineWidth  = 0.7;
			e.CapSize    = 4;
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
			ylim([500 1000]);
		end
		xlim(xRange);
		set(gca,'xtick',x,'xTickLabel',xTickLabel(x));
	end
end
print('-depsc','-painters',fullfile(pwd,[num2str(analyByBlock),'_',num2str(regularGroup),'regulGrp_RT_',num2str(oddSubPlot+evenSubPlot-2),'.eps']));
% saveas(gcf,[analyByBlock,'_',num2str(regularGroup),'regulGrp_RT_',num2str(oddSubPlot+evenSubPlot-2),'sub.bmp']);

% for spss
RtForSpss = reshape(validRtRaw(:,5),ndots*ngroups,numel(unique(validRtRaw(:,2))))';
validRtRaw(validRtRaw(:,3)>4,8)=1;
[meanOfBlock,validRtgSem,validRtgname,validRtgcout] = grpstats(validRtRaw(:,end-3),{validRtRaw(:,1),validRtRaw(:,2),validRtRaw(:,8),validRtRaw(:,4)},{'mean','sem','gname','numel'});
RtMeanForSpss = reshape(meanOfBlock,6,numel(unique(validRtRaw(:,2))))';







cd ..
% close all;
save(['result_control_',num2str(8/analyByBlock),'sess_',num2str(randLocGroupNum),'rdmGrp']);