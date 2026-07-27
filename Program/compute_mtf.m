function result = compute_mtf(img, winSize)
    if nargin < 2
        winSize = 20;
    end
    if winSize < 16
        winSize = 16;
    end
    halfWin = floor(winSize/2);
    [rows, cols] = size(img);

    edgePos = zeros(rows, 1);
    for r = 1:rows
        line = img(r, :);
        grad = abs(diff(line));
        [~, idx] = max(grad);
        edgePos(r) = idx;
    end
    
    if all(edgePos == 0) || std(edgePos) < 1e-6
        result.success = false;
        return;
    end
    
    x = (1:rows)';
    p = polyfit(x, edgePos, 1);
    slope = p(1);
    intercept = p(2);
    
    if abs(slope) < 1e-6
        nlines = rows;
    else
        nlines = round(1 / abs(slope));
        nlines = max(1, min(nlines, rows));
    end
    
    numSuper = floor((rows - nlines) / nlines) + 1;
    if numSuper < 1
        result.success = false;
        return;
    end
    
    superData = zeros(numSuper, winSize * nlines);
    for s = 1:numSuper
        rowIndices = rows - (s-1)*nlines : -1 : rows - s*nlines + 1;
        xEdges = slope * rowIndices + intercept;
        lineData = zeros(nlines, winSize);
        for j = 1:nlines
            r = rowIndices(j);
            xc = xEdges(j);
            xPos = xc - halfWin + (0:winSize-1) + 0.5;
            xi = floor(xPos);
            alpha = xPos - xi;
            xi = max(1, min(cols-1, xi));
            xip1 = xi + 1;
            valLeft = img(r, xi);
            valRight = img(r, xip1);
            lineData(j, :) = (1 - alpha) .* valLeft + alpha .* valRight;
        end
        superData(s, :) = lineData(:)';
    end
    
    superAvg = mean(superData, 1);
    LSF = diff(superAvg);
    N = length(LSF);
    
    window = hann(N)';
    LSF = LSF .* window;
    
    Nfft = 2^nextpow2(N);
    MTF_raw = abs(fft(LSF, Nfft));
    MTF_norm = MTF_raw / MTF_raw(1);
    
    Fs_super = nlines;
    f = (0:Nfft-1) * (Fs_super / Nfft);
    idx = f <= 1;
    result.f = f(idx);
    result.mtf = MTF_norm(idx);
    result.slope = slope;
    result.success = true;
end