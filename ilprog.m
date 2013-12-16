function [ x , exitflag] = ilprog( f,AINEQ,bINEQ,AEQ,bEQ,lb,ub )
% This program tries to find the integer solutions to x
% using branch and bound

%display('Running integer linear program');
global minFval;
global bestX ;
bestX= zeros(size(f'));
minFval= Inf;
%options=optimset('Display', 'off');
options = optimoptions('linprog','Algorithm','simplex','Display', 'off');
ilprogRecursive(f,AINEQ,bINEQ,AEQ,bEQ,lb,ub,options);  
x=bestX;
end

function ilprogRecursive(f,AINEQ,bINEQ,AEQ,bEQ,lb,ub,options)
%% Setting another set of variables

[x,fval,exitflag] = linprog(f,AINEQ,bINEQ,AEQ,bEQ, lb,ub,[],options);
if(exitflag==-2) %infeasible
    %display('infeasible');
    return;
end
if(exitflag==-3) %unbounded
    %display('unbounded')
    return;
end

global minFval;
%[fval minFval];
if(fval>=minFval)
    %exitflag = -8; % pruned
    %display('pruned')
    return
end
epsNew = 0.000000001;

global bestX ;

indices = find(abs(x-double(uint32(x)))>=epsNew);
if(isempty(indices))
    %display('Integer values')
    if(fval<minFval)
        minFval=fval;
        bestX=x;
    end
    return
end
splitIndex = indices(1);


%RIGHT
lb2=lb;
lb2(splitIndex) = ceil(x(splitIndex));
if(lb2(splitIndex)>ub(splitIndex))
    return;
end

ilprogRecursive( f,AINEQ,bINEQ,AEQ,bEQ,lb2,ub,options);

%LEFT
ub1 = ub;
ub1(splitIndex) = floor(x(splitIndex));
if(lb(splitIndex)>ub1(splitIndex))
    return;
end
ilprogRecursive( f,AINEQ,bINEQ,AEQ,bEQ,lb,ub1,options);


end
