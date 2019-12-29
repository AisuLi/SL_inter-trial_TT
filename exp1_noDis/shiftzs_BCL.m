function [zscores]=shiftzs_BCL(counts,type)
% return the nonrecursive outlier deletion criterion which adopt
%shifting Z score criterion (Van Selst & Jolicoeur,1994)
%Van Selst, M., & Jolicoeur,P. A solusion to the effect of sample size
%on outlier elimination. QJEP, 47A,631~650
%
% Useage:
%           z=shiftzs_BCL(count);
%        OR:
%           z=shiftzs_BCL(count,type);
%  Argins:
%           count:  numel in selected cells
% type [1]:
% 1 : modified recursive procedure
% 0 or [] : No recursive procedure
%        allanzhang
%Department of Psychology.
%Northeast normal university
%zhangyang873@yahoo.com.cn
%
% laster revised by yz Apr-21-2009
% 
% adding the modified recursive procedure
% add by yz Jun-1-2009
%
% deal with the matrix of counts
% revised by YZ 14-Mar-2010
if nargin<1
    HelpStr={' return the nonrecursive outlier deletion criterion which adopt'
        'shifting Z score criterion (Van Selst & Jolicoeur,1994)'
        'Van Selst, M., & Jolicoeur,P. A solusion to the effect of sample size'
        'on outlier elimination. QJEP, 47A,631~650'
        ' '
        ' Useage:'
        '           z=shiftzs_BCL(count);'
        '         OR: z=shiftzs_BCL(count,type);'
        '           count:  numel in selected cells'
        ' '
        '           type [1]:'
        '                   1 or [] : modified recursive procedure'
        '                   0: No recursive procedure'
        '        allanzhang'
        'Department of Psychology.'
        'Northeast normal university'
        'zhangyang873@yahoo.com.cn'
        ' '
        'laster revised by yz Apr-21-2009'
        ''
        '% deal with the matrix of counts'
        'Revised by YZ 14-Mar-2010'};
    for i=1:length(HelpStr)
        disp(HelpStr{i});
    end
    return
end

if ~exist('type','var')||isempty(type)
    type=0;
    disp('Attention! no type inputed, using the default parameter 0 no recursive !')
end
%   BGIN
switch type
    case 1
        if numel(counts)>1
            for irow=1:size(counts,1)
                for icolumn=1:size(counts,2)
                    zscores(irow,icolumn)= singleShiftzsMR(counts(irow,icolumn));  %#ok<AGROW>
                end
            end
        else
            zscores=singleShiftzsMR(counts);
        end
    case 0
        if numel(counts)>1
            for irow=1:size(counts,1)
                for icolumn=1:size(counts,2)
                    zscores(irow,icolumn)= singleShiftzs(counts(irow,icolumn));  %#ok<AGROW>
                end
            end
        else
            zscores=singleShiftzs(counts);
        end
    otherwise
        error('The current version of shiftz only support 2 type  the  MR and NR  method');
end



function zscore=singleShiftzs(count)
if count>=100
    %zscore=((count-100)*(2.50/100))+2.50;
    zscore=2.5;
elseif count>=50&&count<100
    zscore=((count-50)*((2.50-2.48)/50))+2.48;
elseif count>=35&&count<50
    zscore=((count-35)*((2.48-2.45)/15))+2.45;
elseif count>=30&&count<35
    zscore=((count-30)*((2.45-2.431)/5))+2.331;
elseif count>=25&&count<30
    zscore=((count-25)*((2.431-2.41)/5))+2.41;
elseif count>=20&&count<25
    zscore=((count-20)*((2.41-2.391)/5))+2.391;
elseif count>=15&&count<20
    zscore=((count-15)*((2.391-2.326)/5))+2.326;
elseif count==14
    zscore=2.31;
elseif count==13
    zscore=2.274;
elseif count==12
    zscore=2.246;
elseif count==11
    zscore=2.22;
elseif count==10
    zscore=2.173;
elseif count==9
    zscore=2.12;
elseif count==8
    zscore=2.05;
elseif count==7
    zscore=1.961;
elseif count==6
    zscore=1.841;
elseif count==5
    zscore=1.68;
elseif count==4
    zscore=1.458;
else
    zscore=1;
end

function zscore=singleShiftzsMR(count)
if count>=100
    %
    zscore=3.5;
elseif count>=50&&count<100
    zscore=3.51-((count-50)*((3.51-3.5)/50));
elseif count>=35&&count<50
    zscore=3.54-((count-35)*((3.54-3.51)/15));
elseif count>=30&&count<35
    zscore=3.55-((count-30)*((3.55-3.54)/5));
elseif count>=25&&count<30
    zscore=3.595-((count-25)*((3.595-3.55)/5));
elseif count>=20&&count<25
    zscore=3.595-((count-20)*((3.64-3.595)/5));
elseif count>=15&&count<20
    zscore=3.75-((count-15)*((3.75-3.64)/5));
elseif count==14
    zscore=3.80;
elseif count==13
    zscore=3.85;
elseif count==12
    zscore=3.92;
elseif count==11
    zscore=4;
elseif count==10
    zscore=4.11;
elseif count==9
    zscore=4.25;
elseif count==8
    zscore=4.475;
elseif count==7
    zscore=4.8;
elseif count==6
    zscore=5.3;
elseif count==5
    zscore=6.2;
elseif count==4
    zscore=8;
else
    zscore=9;
end
