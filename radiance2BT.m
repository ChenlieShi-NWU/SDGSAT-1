function [BT2,BT3] = radiance2BT(L2,L3)
h = 6.626.*10^-34;
c = 2.9979.*10^8;
k = 1.3806.*10^-23;
lamda2 = 10.73;
lamda3 = 11.72;
BT2 = (10^6.*h.*c./(k.*lamda2))./log(2.*10^24.*h.*c^2./(L2.*lamda2^5)+1);
BT3 = (10^6.*h.*c./(k.*lamda3))./log(2.*10^24.*h.*c^2./(L3.*lamda3^5)+1);
end