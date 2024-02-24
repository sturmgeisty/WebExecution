-- Module to supply custom functions to the env. --

return function(Environment)
    local CustomFunctions = {
        getinstances = function() return game:GetDescendants() end;
        getversion = function() return "v1.0.0" end;
    };
    for index, key in next, CustomFunctions do 
        Environment[index] = key;
    end;
end;
