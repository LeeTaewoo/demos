----------------------------------------------------------------------
-- 선형 회귀 예제 (example-linear-regression.lua)
-- 
-- 이 스크립트는 Torch7의 신경망 패키지(nn)와 
-- 최적화 패키지(optim)를 사용하여
-- 선형 회귀의 매우 간단한 단계별 예제를 제공합니다.

-- 노트: 이 스크립트 실행하려면, 다음 줄을 실행하십시오:
-- th script.lua

-- 스크립트를 실행하고 쉘과의 상호작용 결과를 얻기 원하면 다음 줄을 실행하십시오:
-- th -i script.lua

-- 먼저 필요한 패키지들을 require합니다.
-- 노트: optim은 3rd-party 패키지로 따로 설치되어야 합니다.
-- 이 설치는 Torch7의 패키지 매니저를 사용하여 다음과 같이 쉽게 할 수 있습니다:
-- luarocks install optim

require 'torch'
require 'optim'
require 'nn'


----------------------------------------------------------------------
-- 1. 훈련 데이터 생성

-- 모든 회귀 문제들에서, 약간의 훈련 데이터가 필요합니다.
-- 모든 실제 시나리오에서, 데이터는 파일 시스템의 데이터베이스에서 
-- 오고, 디스크에서 로드되어야 합니다. 그런 개별 지도에서,
-- 우리는 데이터 소스를 한 루아 테이블로 만듭니다.

-- 일반적으로, 그 데이터는 임의의 형식으로 저장될 수 있습니다.
-- 그리고 루아의 유연한 테이블 자료 구조를 사용하는 것은 좋은 생각입니다.
-- 여기서 우리는 그 데이터를 한 토치 텐서(2차원 배열)로 저장합니다.
-- 그 텐서의 객 행은 훈련 샘플 하나를 나타냅니다.
-- 그리고 그 텐서의 각 열은 한 변수를 나타냅니다.
-- 첫 번째 열은 타겟 변수입니다, 그리고 다른 열들은 입력 변수들입니다.

-- 데이터는 [Schaum's Outline](http://www.mhprofessional.com/category/?cat=3959)의 한 예제입니다:
-- Dominick Salvator 그리고 Derrick Reagle
-- Shaum's Outline of Theory and Problems of Statistics and Economics
-- 2nd edition
-- McGraw-Hill
-- 2002

-- 데이터는 옥수수 생산량을 비료 및 살충제 양과 관련짓습니다.
-- 그 책의 157 쪽을 보십시오.

-- 이 예제에서, 우리는 사용된 비료와 살충제 양을 가지고 
-- 옥수수 생산량을 예측하길 원합니다.
-- 다른 말로: 비료와 살충제가 우리의 두 입력 변수들이고,
-- 옥수수가 우리의 타겟 값입니다.

--  {옥수수, 비료, 살충제}
data = torch.Tensor{
   {40,  6,  4},
   {44, 10,  4},
   {46, 12,  5},
   {48, 14,  7},
   {52, 16,  9},
   {58, 18, 12},
   {60, 22, 14},
   {68, 24, 20},
   {74, 26, 21},
   {80, 32, 24}
}


----------------------------------------------------------------------
-- 2. 모델 정의 (예측 변수)

-- 모델은 (모듈이라 불리는) 한 층을 가질 것입니다.
-- 그 층은 두 입력(비료와 살충제)을 받아서 한 출력(옥수수)을 만듭니다.

-- 아래 특정된 선형 모델은 세 개의 파라미터를 가짐을 유념하십시오:
--   하나는 비료에 할당된 가중치
--   하나는 살충제에 할당된 가중치
--   하나는 바이어스 항에 할당된 가중치

-- 몇몇 다른 모델 특정화 방식에서는, 훈련 데이터가 상숫값 1을 가지도록
-- 할 수도 있습니다. 그러나 선형 모델에서는 그렇게 하지 않습니다.

-- 그 선형 모델은 반드시 컨테이너에 있어야 합니다.
-- 시퀀셜 컨테이너가 적절합니다, 왜냐하면 각 모듈의 출력들이 
-- 그 모델의 다음 모듈의 입력이 되기 때문입니다.
-- 이 경우는, 모듈이 오직 하나만 있습니다.
-- 더 복잡한 경우들에서, 다수의 모듈들이 
-- 시퀀셜 컨테이너를 사용하여 쌓일 수 있습니다.

-- 그 모듈들은 모두 신경망 패키지 안에 정의되어 있습니다.
-- 그 패키지의 이름은 'nn'입니다.

model = nn.Sequential()                 -- 컨테이너를 정의합니다
ninputs = 2; noutputs = 1
model:add(nn.Linear(ninputs, noutputs)) -- 그 유일한 모듈을 정의합니다


----------------------------------------------------------------------
-- 3. (최소화 되기 위한) 손실 함수 정의.

-- 그 예제에서, 우리는 우리의 선형 모델 예측과 그 데이터세트에서 
-- 사용 가능한 정답 사이의 평균 제곱 오차를 최소화합니다.

-- 토치는 신경망을 훈련시키기 위해 흔히 사용되는 많은 판별식들을 제공합니다. 

criterion = nn.MSECriterion()


----------------------------------------------------------------------
-- 4. 모델 훈련

-- 위에서 정의된 손실을 최소화 하기 위해, '모델'에서 정의된 선형 모델을 
-- 사용하여, 우리는 통계적 경사 강하(stochastic gradient descent, SGD) 
-- 절차를 따릅니다. 

-- SGD는 훈련 데이터 양이 많을 때 좋은 최적화 알고리즘입니다.
-- 그리고 전체 훈련 세트에 걸쳐 그 손실 함수의 기울기를 추정하는 것은
-- 너무 비용이 많이듭니다.

-- 한 임의의 복잡한 모델을 가지고, 우리는 그것의 훈련 가능한 
-- 파라미터들과 우리의 이 파라미터들에 대한 손실 함수의 기울기들을 
-- 조사할 수 있습니다. 다음과 같이 함으로써:

x, dl_dx = model:getParameters()

-- 다음 코드에서, 우리는 한 closure, feval을 정의합니다. 
-- feval은 주어진 시점 x에서의 손실 함수의 값과 x에 대한 그 함수의 
-- 기울기를 계산합니다. x는 훈련 가능한 가중치들의 벡터입니다.
-- 그것은, 이 예제에서, 우리 모델의 선형 행렬의 모든 가중치들과
-- 한 바이어스 입니다.

feval = function(x_new)
   -- 만약 두 변수가 다르면, x를 x_new로 설정합니다. 
   -- (이 간단한 예제에서, x_new는 보통 항상 x를 가리킵니다,
   -- 그래서 복사는 필요없습니다)
   if x ~= x_new then
      x:copy(x_new)
   end

   -- 새 훈련 예제를 선택합니다
   _nidx_ = (_nidx_ or 0) + 1
   if _nidx_ > (#data)[1] then _nidx_ = 1 end

   local sample = data[_nidx_]
   local target = sample[{ {1} }]      -- 이 우스워 보이는 문법은 
   local inputs = sample[{ {2,3} }]    -- 배열들의 단면을 쓸 수 있게 합니다.

   -- 기울기들을 초기화 (기울기들은 항상 누적됩니다, 배치 메소드들을 
   -- 수용하기 위해)
   dl_dx:zero()

   -- 그 샘플을 위한, 손실 함수의 값과 그 함수의 x에 대한 편미분값을 계산합니다.
   local loss_x = criterion:forward(model:forward(inputs), target)
   model:backward(inputs, criterion:backward(model.output, target))

   -- loss(x)와 dloss/dx를 리턴합니다
   return loss_x, dl_dx
end

-- 위에서 주어진 함수를 가지고, 우리는 SGD를 사용하여 모델을 쉽게 훈련시킬 수 있습니다.
-- 그것을 위해, 네 개의 중요한 파라미터들을 정의할 필요가 있습니다:
--   + 학습률: 그 기울기의 각 통계적 추정에서 취해지는 스텝의 크기
--   + 가중치 감소, 그 정답을 레귤러라이즈 하기 위해 (L2 레귤러라이제이션)
--   + 모멘텀 항, 시간에 걸쳐 스텝들을 평균내기 위해
--   + 학습률 감소, 그 알고리즘이 더 정확하게 수렴하게 하기 위해

sgd_params = {
   learningRate = 1e-3,
   learningRateDecay = 1e-4,
   weightDecay = 0,
   momentum = 0
}

-- 이제 가봅시다... 이제 우리가 할 일은 데이터세트에서 돌리는 것입니다.
-- 한 특정한 수의 반복 동안, 그리고 각 반복에서 통계적 갱신을 수행합니다.
-- 여기서 그 반복의 횟수는 실험적으로 찾아집니다,
-- 그러나 보통 크로스-밸리데이션(cross-validation)을 사용하여 결정되어야 합니다.

-- 우리의 훈련 데이터 전체에 걸쳐 1e4(10,000) 번 돌립니다.
for i = 1,1e4 do

   -- 이 변수는 평균 손실을 추정하기 위해 사용됩니다
   current_loss = 0

   -- 한 에포크는 우리 훈련 데이터를 완전히 한 번 순회할 때마다 
   -- 1씩 증가하는 변수입니다.
   for i = 1,(#data)[1] do

      -- optim 몇 개의 최적화 알고리즘을 담고 있습니다.
      -- 이 모든 알고리즘들은 같은 파라미터들을 가지고 있다고 가정합니다:
      --   + 손실을 계산하는 closure와 그것의 주어진 point x에 대한 기울기
      --   + 한 point x
      --   + 알고리즘에 따라 달라지는 몇몇 파라미터들
      
      _,fs = optim.sgd(feval,x,sgd_params)

      -- optim의 함수들은 모두 두 가지를 리턴합니다:
      --   + 최적화 메소드로 찾은 (여기서는 SGD) 새로운 x 
      --   + 그 알고리즘에서 사용되는 모든 point들에서의 손실 함수의 값.
      --     SGD는 리스트가 오직 하나의 값만 담게 하기 위해 
      --     오직 그 함수를 한 번만 추정합니다.

      current_loss = current_loss + fs[1]
   end

   -- 에포크에서의 평균 에러를 보고합니다
   current_loss = current_loss / (#data)[1]
   print('current loss = ' .. current_loss)

end


----------------------------------------------------------------------
-- 5. 훈련된 모델 시험.

-- 모델이 훈련되었으므로, 거기에 새로운 샘플들의 값을 대입해 봄으로써
-- 그것을 시험할 수 있습니다.

-- 다음 텍스트는 행렬 기법을 사용하여 그 모델을 정확히 풉니다.
--   corn = 31.98 + 0.65 * fertilizer + 1.11 * insecticides

-- 우리는 우리의 근사치 결과들과 텍스트의 결과들을 비교합니다.

text = {40.32, 42.92, 45.33, 48.85, 52.37, 57, 61.82, 69.78, 72.19, 79.42}

print('id  approx   text')
for i = 1,(#data)[1] do
   local myPrediction = model:forward(data[i][{{2,3}}])
   print(string.format("%2d  %6.2f %6.2f", i, myPrediction[1], text[i]))
end

