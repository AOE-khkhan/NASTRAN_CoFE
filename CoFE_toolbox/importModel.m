% Read NATRAN input file and convert it to instance of class fem
% Anthony Ricciardi
%
% Inputs
% filename = [string] name of text input file in NASTRAN format
%
% Output
% FEM [Cell Structured Data] model data
%
%
function FEM = importModel(filename)

%% initialize FEM
FEM = fem;

%% read data from input file
data = importData(filename);

%% initial data processing
placeholder_list = [];
placeholder_count = zeros(200,1); % 200 is arbitrary
placeholders = 0;

for i = 1:size(data,2)
    entry = upper(data(i).fields{1});
    index = strcmp(placeholder_list,entry);
    if any(index) == 0
        placeholders = placeholders + 1;
        placeholder_list{placeholders} = entry;
        index = strcmp(placeholder_list,entry);
    end
    
    ind = find(index);
    if size(ind,2) > 1; error('There should only be one matching entry name'); end
    placeholder_count(ind) = placeholder_count(ind)+1;

end
placeholder_count = placeholder_count(1:placeholders);

%% initialize placeholders
for i = 1:placeholders
    entry = placeholder_list{i};
    eval(['placeholder_',entry,'(placeholder_count(i)) = ', lower(entry) ,';']); 
    
    if any(strcmp(entry,FEM.entryList)) == 0
        error(strcat(entry,' entry not supported.'))
    end
end

%% execute "initialize" method
for i = size(data,2):-1:1
    entry = upper(data(i).fields{1});
    ind = find(strcmp(placeholder_list,entry));
    eval(['placeholder_',entry,'(placeholder_count(ind)) = placeholder_',entry,'(placeholder_count(ind)).initialize(data(i).fields) ;']);    
    placeholder_count(ind) = placeholder_count(ind)-1;
end

%% save placeholders to FEM object
for i = 1:placeholders
    entry = placeholder_list{i};
    eval(['FEM.(entry) = placeholder_',entry,';']);
end

end