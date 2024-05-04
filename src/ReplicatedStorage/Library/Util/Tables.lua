local Tables = {};

function Tables.Shuffle(t)
    if t == nil then return end;
    local n=#t;
    for i=1, n-1 do
        local l=math.random(i,n);
        t[i],t[l]=t[l],t[i];
    end
end

return Tables;