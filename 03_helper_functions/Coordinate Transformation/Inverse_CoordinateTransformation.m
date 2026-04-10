function [R_inv,T_inv] = Inverse_CoordinateTransformation(R,T)
    R_inv = R';
    T_inv = -R' *T;
end

