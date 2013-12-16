function TravellingSalesmanProblem( filename )
%Solving TSP
%Read from given file
clc;

%% GET DATA
% Get parsed string
googleAPIString = GetParsedStringFromFile(filename);

%distance matrix from file
DistanceMatrix = GetDistanceFromFile(googleAPIString)';

%% VARIABLES
% number of vertices 
nVertices = length(DistanceMatrix);

% number of edges
% vertex one goes to all except itself = (n-1) +
% all other vertices goes to all others except vertex one and itself = (n-1)*(n-2)
nEdges = (nVertices-1)*(nVertices-1);

% nEdges (0 or 1) To find the edges
% nVertices ( ti and tj ) To ensure connectivity - We dont care about cycle
% , we dont have cycle
nDecisionVariables = nEdges + nVertices ;

% cost
f =zeros(1,nDecisionVariables);


%% IN CRITERIA
%All nodes have in criteria except node 0
AIN_EQ = zeros(nVertices-1,nDecisionVariables);

%% OUT CRITERIA
%Node 1 has a strict out criteria i.e it should have one out edge
AOUT_NODE1_EQ = zeros(1,nDecisionVariables);

% Other nodes May or May not have an out edge 
% Hence would have an inequality constraint
AOUT_INEQ = zeros(nVertices-1,nDecisionVariables);

%% CYCLE CRITERIA
ACYCLE_INEQ= zeros(nEdges,nDecisionVariables);

%% ALGORITHM TO UPDATE THE VALUES IN THE MATRICES

counter =1;
%VertexFrom = [];
%VertexTo =[];

for i=1:nVertices
    for j= 2:nVertices % ignore the first row, since there is no edge to first node
        if (i==j)
            continue;
        end
        
        % cost
        f(counter) = DistanceMatrix(i,j); 
        
        % in criteria atleast one IN node
        AIN_EQ(j-1,counter) =1;
        
        % out criteria
        if (i==1) %strictly one OUT node
            AOUT_NODE1_EQ(1,counter)=1;
        else % one OUT node for all except last
            AOUT_INEQ(i-1,counter) =1;
        end
        
        %cycle criteria
        ACYCLE_INEQ(counter,counter) =nVertices;
        ACYCLE_INEQ(counter,nEdges+ i)= 1;
        ACYCLE_INEQ(counter,nEdges+ j)= -1;
        
        % Book keeping
        %VertexFrom(counter,1)=i;
        %VertexTo(counter,1)=j;
        counter= counter+1;
    end
end

%% UPDATING b VALUES
% IN
bIN_EQ = ones(nVertices-1,1);

%OUT
bOUT_NODE1_EQ = 1;
bOUT_INEQ = ones(nVertices-1,1);

%CYCLE
bCYCLE_INEQ=zeros(nEdges,1);
bCYCLE_INEQ(:)=nVertices-1;

%% FORM THE MATRICES

AEQ = [AIN_EQ ;AOUT_NODE1_EQ];
bEQ = [bIN_EQ ;bOUT_NODE1_EQ];

AINEQ = [AOUT_INEQ; ACYCLE_INEQ];
bINEQ = [bOUT_INEQ; bCYCLE_INEQ];


lb = zeros(1,nDecisionVariables);
tUpperBound = zeros(1,nVertices);
tUpperBound(:) = nVertices-1;
ub = [ones(1,nEdges) tUpperBound];

tic
x = ilprog(f,AINEQ,bINEQ,AEQ,bEQ,lb,ub);
toc
%% PRINT ILP
%[VertexFrom VertexTo x(1:nEdges) f(1:nEdges)']

%% Print expected results
vertices = (1:nVertices)';
t = x(nEdges+1:nDecisionVariables);
ResultMatrix = [ t vertices];
ResultMatrix = sortrows(ResultMatrix,1);
display(ResultMatrix(:,2));

%% CHECK ANSWER
%xAnswer = [0 1 0 0 0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0 2 1 5 3 4];
%[f*x f*xAnswer']
end

function parsedString = GetParsedStringFromFile(filename)

fid = fopen(filename);
locationString='';
tline = fgets(fid);
while ischar(tline)
    splitString = strsplit(tline,{'(',')'});
    latString=strsplit(splitString{2},{', '});
    locationString=strcat(locationString,latString{1},',',latString{2},'|');
    tline = fgets(fid);
end
fclose(fid);
parsedString = strcat('http://maps.googleapis.com/maps/api/distancematrix/xml?origins=',locationString,'&destinations=',locationString,'&sensor=false');
end

function [DistanceMatrix] =GetDistanceFromFile(googleAPIString)

% Parse the file

% use google to get xml
filename = 'Nodes.xml';
urlwrite(googleAPIString,filename);

% read xml
DOMnode = xmlread(filename);
allListitems = DOMnode.getElementsByTagName('row');

%update size
% create distance matrix
DistanceMatrix = zeros(2,2);

for k = 0:allListitems.getLength-1
    thisListitem = allListitems.item(k);
    thisListElements = thisListitem.getElementsByTagName('element');
    for j = 0:thisListElements.getLength-1
        elementNode = thisListElements.item(j);
        distanceElement = elementNode.getElementsByTagName('distance');
        valueElement = distanceElement.item(0).getElementsByTagName('value').item(0).getTextContent;   
        DistanceMatrix(k+1,j+1)=str2double(valueElement);
    end
end

end
