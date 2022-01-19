
function [output] = findthreshold( inputarray, percentile, sign)
%To find threshold that only X% of elements surpass
%   Detailed explanation goes here

thresholds = min(inputarray):0.01:max(inputarray);

for k = 1:length(thresholds);
    if sign == 'above'
        fraction = length(find(inputarray>thresholds(k)))/length(inputarray);
        
        if fraction<= percentile/100;
            output = thresholds(k)
            break
        else
            continue
        end
        
    elseif sign == 'below'
        fraction = length(find(inputarray<thresholds(k)))/length(inputarray);
    end
    
    if fraction>= percentile/100;
        output = thresholds(k)
        break
    else
        continue
    end
    
    
end

end

