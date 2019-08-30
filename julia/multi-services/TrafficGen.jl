#include("Setting.jl")
using Distributions
using HDF5

function to_watt(x)
    return 10^(x / 10)
end

function to_dBW(x)
    return 10*log10(x)
end

### Exponential distribution of channel_gain
function exp_gain(dist, mode = 0)
    g0 = -40 #dB
    g0_W = to_watt(g0)
    d0 = 1 #1 m
    mean = g0_W*((d0/dist)^4)

    if (mode == 0)
        gain_h = rand(Exponential(mean))
    else
        # gain_h = rand(Exponential(mean))
        gain_h = mean
    end
    # println("here1: ", dist, " : ", mean, " : ",gain_h)
    return gain_h #in Watts
end

# function noise_per_gain(gain)  #N0/h
#     return N0/gain
# end

function shanon_capacity(gain)
    SNR = Tx_Power * gain / N0
    Capacity = BW * log2(1 + SNR)     #Shannon capacity bps
    return Capacity
end

function mobile_gen()
    if(REUSED_TRAFFIC)
        return simple_read_data()
    else
        dist_list = zeros(Numb_Services,NumbDevs)
        gain_list = zeros(Numb_Services,NumbDevs)
        capacity  = zeros(Numb_Services,NumbDevs)
        D_n       = zeros(Numb_Services,NumbDevs)
        for s =1:Numb_Services
            dist_list[s,:] = rand(Uniform(Dist_min,Dist_max),NumbDevs)
            if(ByDataset)
                D_n[s,:]   = D_DS*ones(NumbDevs)
            else
                D_n[s,:]   = rand(Uniform(D_min,D_max),NumbDevs)
            end

            for n=1:NumbDevs
                gain_list[s,n] = exp_gain(dist_list[s,n])
                capacity[s,n]    = shanon_capacity(gain_list[s,n])
            end

        end
        simple_save_data(dist_list, gain_list, capacity, D_n)
        return dist_list, gain_list, capacity, D_n
    end
end

# function mobile_gen_sub1()
#     if(REUSED_TRAFFIC)
#         return simple_read_data("data_sub1.h5")
#     else
#         dist_list = zeros(NumbDevs)
#         gain_list = zeros(NumbDevs)
#         ratios    = zeros(NumbDevs)
#         D_n       = zeros(Numb_D,NumbDevs)
#         for d=1:Numb_D
#             dist_list[:] = rand(Uniform(Dist_avg-2,Dist_avg+2),NumbDevs)
#             step_size = (1-D_ratios[d])/(1+D_ratios[d]) * D_avg/(NumbDevs/2.)   #(D_ratios[d]-1)/(1+D_ratios[d]) * D_avg/(NumbDevs/2.)
#             # D_min = D_avg - step_size * (NumbDevs/2.)
#             # D_max = D_avg + step_size * (NumbDevs/2.)
#             # D_n[d,:]   = collect(D_min:((D_max-D_min)/(NumbDevs-1)):D_max)
#
#             for n=1:NumbDevs
#                 if(n <= NumbDevs/2.)
#                     D_n[d,n] = D_avg - (NumbDevs/2. - n + 1 )*step_size
#                 else
#                     D_n[d,n] = D_avg + ( n - NumbDevs/2. )*step_size
#                 end
#
#                 gain_list[n] = exp_gain(dist_list[n], 2)
#                 ratios[n]    = noise_per_gain(gain_list[n])
#             end
#
#         end
#         # println("D_max:",D_n[:,NumbDevs])
#         # println("D_min:",D_n[:,1])
#         # println("D_avg1:",mean(D_n[1,:]))
#         # println("D_avg2:",mean(D_n[2,:]))
#         # println("D_avg3:",mean(D_n[3,:]))
#
#         simple_save_data(dist_list, gain_list, ratios, D_n, "data_sub1.h5")
#         return dist_list, gain_list, ratios, D_n
#     end
# end
#
# function mobile_gen_sub2()
#     if(REUSED_TRAFFIC)
#         return simple_read_data("data_sub2.h5")
#     else
#         dist_list = zeros(Numb_Dis,NumbDevs)
#         gain_list = zeros(Numb_Dis,NumbDevs)
#         ratios    = zeros(Numb_Dis,NumbDevs)
#         D_n       = zeros(NumbDevs)
#
#         for d=1:Numb_Dis
#             step_size = (1-Dis_ratios[d])/(1+Dis_ratios[d]) * Dist_avg/(NumbDevs/2.)   #(D_ratios[d]-1)/(1+D_ratios[d]) * D_avg/(NumbDevs/2.)
#             # D_min = D_avg - step_size * (NumbDevs/2.)
#             # D_max = D_avg + step_size * (NumbDevs/2.)
#             # dist_list[d,:] = collect(Dist_min:((Dist_max-Dist_min)/(NumbDevs-1)):Dist_max)
#
#             D_n[:]   = collect(D_min:((D_max-D_min)/(NumbDevs-1)):D_max)
#
#             for n=1:NumbDevs
#                 if(n <= NumbDevs/2.)
#                     dist_list[d,n] = Dist_avg - (NumbDevs/2. - n + 1 )*step_size
#                 else
#                     dist_list[d,n] = Dist_avg + ( n - NumbDevs/2. )*step_size
#                 end
#
#                 gain_list[d,n] = exp_gain(dist_list[d,n], 2)
#                 ratios[d,n]    = noise_per_gain(gain_list[d,n])
#             end
#         end
#
#         # println("Dist_max:",dist_list[:,NumbDevs])
#         # println("Dist_min:",dist_list[:,1])
#         # println("Dist_avg1:",mean(dist_list[1,:]))
#         # println("Dist_avg2:",mean(dist_list[2,:]))
#         # println("Dist_avg3:",mean(dist_list[3,:]))
#
#         simple_save_data(dist_list, gain_list, ratios, D_n, "data_sub2.h5")
#         return dist_list, gain_list, ratios, D_n
#     end
# end

function simple_save_data(dist_list, gain_list, capacity, D_n, filename="data.h5")
    h5open(filename, "w") do file
        write(file,"dist_list", dist_list)
        write(file,"gain_list", gain_list)
        write(file,"capacity", capacity)
        write(file,"D_n", D_n)
    end
end

function simple_read_data(filename="data.h5")
    h5open("data.h5", "r") do file
        dist_list =read(file,"dist_list")
        gain_list =read(file,"gain_list")
        capacity =read(file,"capacity")
        D_n = read(file,"D_n")
        return dist_list, gain_list, capacity, D_n
    end
end

# mobile_gen()