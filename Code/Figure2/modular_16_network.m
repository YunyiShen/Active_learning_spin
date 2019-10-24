%module16; 

num_iter = 5; 
%learn_oracle; 

cfish = 0; 
rec_fish = zeros(num_j, num_j,num_iter + 1); 
rec_fishd = zeros(num_j, num_iter + 1); 

for ii = 1: num_iter + 1
    cfish = cfish + fisher_inf_exact(j_mat, rec_vec(:, ii));
    rec_fish(:, :, ii) = cfish; 
    [eigv, eigd] = eig(cfish); 
    rec_fishd(:, ii) = diag(eigd); 
end

semilogy(rec_fishd) 

stepsz = 1e-1;
mixing_time = 1e5;
num_epoch = 10000;
samplingsz = 5e3;
samplingmix = 1e3;
sample_size = 5e6; 
train_with_oracle

steps = rec_ctrain{1}.steps; 
for ii = 1: num_iter + 1
    cdat = rec_ctrain{ii};    
    meanerr = cdat.rec_mean; 
    topkerr = cdat.rec_topk(:, 1); 
    subplot(1, 2, 1)
    plot(steps, meanerr)
    hold on 
    subplot(1, 2, 2)
    plot(steps, topkerr)
    hold on 
end
hold off
