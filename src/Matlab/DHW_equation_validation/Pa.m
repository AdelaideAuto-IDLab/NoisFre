function pa = Pa(d,n,m)
% Eqn.(1)
% https://math.stackexchange.com/questions/3335630/probability-problem-roll-a-n-sided-dice-for-m-times-the-probablity-to-have-at#mjx-eqn-eq2
    pa = 0;
    for a=1:n-d
        for z=a+d:n
            pa = pa + P(a,z,n,m);
        end
    end
end

