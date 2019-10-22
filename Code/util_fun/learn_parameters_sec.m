function [cur_j, cur_h, output_dat] = learn_parameters(cur_j, cur_h, train_dat)
%Update current parameters by training on the Bayesian posterier
%   Detailed explanation goes here

num_spin = size(cur_j, 1);
num_j = num_spin * (num_spin - 1) / 2;
num_round = train_dat.round;
num_epoch = train_dat.epoch;
j_mat = train_dat.j_mat; %h_vec = train_dat.h_vec;
corrs = train_dat.corrs; %means = train_dat.means;
decayp = train_dat.decayp;
stepsz = train_dat.stepsz; counter = train_dat.counter;
exter_h = train_dat.exter_h;
lam_l2 = train_dat.lam_l2;
samplingsz = train_dat.samplingsz; samplingmix = train_dat.samplingmix;
rec_gap = train_dat.rec_gap; 
gsteps = train_dat.gsteps;
fish_samples = train_dat.fish_samples;
fish_mix = train_dat.fish_mix;
fish_epsi = train_dat.fish_epsi;
fish_scale = 1;

num_rec = floor(num_epoch / rec_gap);
rec_l2 = zeros(num_rec, 1);

list_step = 1: rec_gap: num_round * num_epoch;

rec_count = 1;

rec_jgrad = zeros(num_spin, num_spin, num_round);
%rec_hgrad = zeros(num_spin, num_round);

cfish = eye(num_j);
sq_spin = num_spin ^ 2; 
aux_mat = reshape((1: sq_spin), num_spin, num_spin)';

node_list = reshape(triu(aux_mat, 1), sq_spin, 1);
node_list(node_list == 0) = [];
node_list = sort(node_list);

for jj = 1: num_epoch
    if mod(jj, rec_gap) == 1
        rec_l2(rec_count) = norm(cur_j - j_mat);
        rec_count = rec_count + 1;
        plot(rec_l2(1: rec_count - 1))
        drawnow
        if mod(jj, 2000) == 1
            disp(rec_l2(rec_count - 1))
        end
    end
    
    if mod(jj, gsteps) == 0
        cfish = zeros(num_j);
        for kk = 1: num_round
            cfish = cfish + fisher_inf(make_spin_sample(cur_j, exter_h(:, kk),...
                fish_samples, fish_mix));
        end
        cfish = cfish + fish_epsi * eye(num_j);    
        %inv_cfish = inv(cfish);
        fish_scale = 70 * fish_epsi;
    end
    
    for kk = 1: num_round
        cur_sample = make_spin_sample(cur_j, cur_h + exter_h(:, kk), samplingsz, samplingmix);
        corr_para = (cur_sample * cur_sample') / samplingsz;
        %mean_para = mean(cur_sample, 2);
        %[corr_para, mean_para] = exact_moments(cur_j, cur_h + rec_bestdir(:, kk) * rec_bestinten(kk));
        rec_jgrad(:, :, kk) = corr_para - corrs(:, :, kk);
        %rec_hgrad(:, kk) = mean_para - means(:, kk);
    end

    % Compute stepsize and sum over all gradient over history 
    cur_stepsz = stepsz / counter ^ decayp;
    gradj = sum(rec_jgrad, 3) - lam_l2 * sign(wthresh(cur_j, 's', 1e-2));
    gradjres = gradj(node_list);
    gradjres = cfish \ gradjres;
    temgrad = zeros(num_spin);
    temgrad(node_list) = gradjres;
    gradjn = (temgrad.' + temgrad) * fish_scale;
    cur_j = cur_j + cur_stepsz * gradj;
    %cur_j = wthresh(cur_j, 's', 1e-6);
    %cur_h = cur_h + cur_stepsz * sum(rec_hgrad, 2);
    counter = counter + 1;

end

output_dat = struct('steps', list_step, 'rec_l2', rec_l2);

end
