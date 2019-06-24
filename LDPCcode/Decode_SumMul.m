function [isSuc, errorframenum, errorbitnum] = Decode_SumMul( rcode, H_index, H_index_len, H_var, H_var_len, u, v, H_ldpc, LDPCEnCode )
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
                tmp = 1;
                for tt = 1:1:H_index_len(ii,1)
                    if tt == jj
                        continue;
                    end
                    % k = H_index(ii,tt)
                    %tmp = tmp * tanh(v(H_index(ii,tt),find_varIndex(ii,H_index(ii,tt),H_var, H_var_len))/2);%H_index(ii,tt)��ʾ��iiУ�鷽�̵ĵ�tt���߶�Ӧ�ı����ڵ������
                    tmp = tmp * tanh(v(H_index(ii,tt),ii)/2);
                end
                
                tmpans = 2*atanh(tmp);
                if tmpans > 100
                    u(ii,H_index(ii,jj)) = 100;
                elseif tmpans < -100
                    u(ii,H_index(ii,jj)) = -100;
                else
                    u(ii,H_index(ii,jj)) = tmpans;
                end
                
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

function index = findIndex(ii, num, H_index, H_index_len) 
    %���ڵ�num��У�鷽�̣�Ѱ�������ӵĵ�ii���ڵ��������ӵ����нڵ��еı��
    index = -1;
    for tt = 1:1:H_index_len(num,1)
        if(H_index(num,tt)==ii)
            index = tt;
            break;
        end
    end
    if(index == -1)
        disp('û���ҵ�H_index������')
    end
end

function index = find_varIndex(ii, num, H_var, H_var_len) 
    %���ڵ�num���ڵ㣬Ѱ�������ӵĵ�ii��У�鷽���������ӵ�����У�鷽���еı��
    index = -1;
    for tt = 1:1:H_var_len(num,1)
        if(H_var(num,tt)==ii)
            index = tt;
            break;
        end
    end
    if(index == -1)
        disp('û���ҵ�H_var������')
    end
end