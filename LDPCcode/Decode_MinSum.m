function [isSuc, errorframenum, errorbitnum] = Decode_MinSum( rcode, H_index, H_index_len, H_var, H_var_len, u, v, H_ldpc, LDPCEnCode, a )
%DECODE Summary of this function goes here
%   Detailed explanation goes here

%�˺���û��ʵ��ѭ�������Ĺ��ܣ���Ҫ������д����
%ǰ����������ÿһ��У�鷽�̰����Ľڵ�λ�õ�����
%������������ÿһ�������ڵ��������ЩУ�鷽��


%rcode�ǽ��ܵ���1x2016�����֣�Ӧ�����Ѿ�����4*snr��ֵ
%     H_rec = zeros(1,2016); %���ڱ���1008�ε��������Ŷ�����
%     for ii = 1:1:1008
%         tmprec = zeros(1,8);
%         for jj = 1:1:H_index_len(ii,1)
%             tmp = 1;
%             for tt = 1:1:H_index_len(ii,1)
%                 if tt == jj
%                     continue;
%                 end
%                 tmp = tmp * tanh(rcode(1,H_index(ii,tt))/2);
%                 
%             end
%             tmpans = 2*atanh(tmp);
%             if tmpans > 100
%                 tmprec(1,jj) = 100;
%             elseif tmpans < -100
%                 tmprec(1,jj) = -100;
%             else
%                 tmprec(1,jj) = tmpans;
%             end
%             
%         end
%         %У������Ŷȴ��ݸ��������Ŷ�
%         for jj = 1:1:H_index_len(ii,1)
%             H_rec(1,H_index(ii,jj)) = H_rec(1,H_index(ii,jj)) + tmprec(1,jj);
%         end
%     end
%     retcode = rcode + H_rec;


%H_index, H_index_len, H_var, H_var_len, u, v
%H_index(i,j) ��ʾ��i��У��ڵ����ĵ�j���ڵ��λ������
%H_var(i,j)��ʾ��i�������ڵ����ĵ�j��У�鷽�̵�λ������
    isSuc = 0;
    Vpan = zeros(1,2016);
    u0 = rcode; %u0��ʾ��ʼ�����Ŷ�
    for iter = 1:1:30%������30��
        for ii = 1:1:2016 %��ÿ�������ڵ���м���
            %����vi->j��ֻ��Ҫ��H_var�õ����бߵĹ�ϵ
            %u��һ��1008x2016�ľ���v��һ��2016x1008�ľ���
            
            for jj = 1:1:H_var_len(ii,1)%ÿ�������ڵ���������ô����
                
                v(ii,H_var(ii,jj)) = u0(1,ii);
                for tt = 1:1:H_var_len(ii,1)%ÿ�������ڵ����һ��ѭ��
                    if tt == jj %��Ӧk!=j������
                        continue;
                    end
                    %v(ii,jj) = v(ii,jj) + u(H_var(ii,tt),findIndex(ii,H_var(ii,tt),H_index, H_index_len));
                    v(ii,H_var(ii,jj)) = v(ii,H_var(ii,jj)) + u(H_var(ii,tt),ii);
                end
                
            end
        
        end
        %��һ���ֽ�����v(ii,jj)��ʾ����ii�����ڵ����jj��������vֵ��ע��У��ڵ��Ӧ����H_var(ii,jj)
        %��ʼ�ڶ�����
        for ii = 1:1:1008
            for jj = 1:1:H_index_len(ii,1)
                minv = 1000000;
                sig = 1;
                for tt = 1:1:H_index_len(ii,1)
                    if tt == jj
                        continue;
                    end
                    sig = sig * getsymbol(v(H_index(ii,tt),ii)); %ȷ������
                    if minv > abs(v(H_index(ii,tt),ii))
                        minv = abs(v(H_index(ii,tt),ii));
                    end
                end
                
                u(ii,H_index(ii,jj)) = sig * minv * a;               
            end
        end
        
        %���������о�
        Vpan(1,:) = 0;
        for ii = 1:1:2016
            Vpan(1,ii) = u0(1,ii);
            for jj = 1:1:H_var_len(ii,1)
                Vpan(1,ii) = Vpan(1,ii) + u(H_var(ii,jj),ii);
            end
            if Vpan(1,ii)<0
                Vpan(1,ii) = 1;
            else
                Vpan(1,ii) = 0;
            end
        end
        
        %ͳ���Ƿ��д���
        judge = zeros(1,1008);
        if(mod(Vpan * H_ldpc',2) == judge)
            isSuc = 1; %��ȷ�ˣ�����ѭ��
            break;
        end        
    end
    
    if isSuc == 1 %û����
        errorframenum = 0;
        errorbitnum = 0;
    else
        errorframenum = 1;
        errorbitnum = 0;
        for ii = 1009:1:2016
            if(Vpan(1,ii)~=LDPCEnCode(1,ii))
                errorbitnum = errorbitnum + 1;
            end
        end
    end
end

function ret = getsymbol(a)
    if(a >= 0)
        ret = 1;
    else
        ret = -1;
    end
end
