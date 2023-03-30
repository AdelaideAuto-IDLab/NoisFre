function p = Q(a,z,n,m)
% Eqn.(2) at
% https://math.stackexchange.com/questions/3335630/probability-problem-roll-a-n-sided-dice-for-m-times-the-probablity-to-have-at
    if(a<1)
        a = 1;
    end
    if(z>n)
       z = n; 
    end
    if(a<=z)
% %       cdf = ((z-a+1)/n)^m; %the dice game
%         cdf = 0;
%         for i = a:z
%         pdf = 1/n; % the pdf of discrete uniform distribution is 1/n
%             cdf = cdf + pdf;
%         end
        cdf = 0;
        for i = a:z
            pdf = binopdf(i,n,0.5);
            cdf = cdf + pdf;
        end
        
        p = cdf^m;
    else
        p = 0;
    end
end

