function [out] = LPER_shns(model,opts)
	%-------------------------------------------------------------------------
	% This program implements our proposed sinkhorn algorithm with numerical stabilty
	% for LP problem with entropic regularization.
	% 
	% Input:
	%     model --- the LP model structure with fields:
	%				--- general ---
	%               m, n   		dimension of rows and cols
	%				obj    		matrix C
	%               cst    		constraints
	%
	%	   opts --- the option structure with fields:
	%				epsilon   	parameter of entropic regularization
	%				itermax   	maximum number of iteration
	%				add_coup  	whether to do additional coupling in the end of the algorithm
	%               
	%
	% Output:
	%       out --- the output structure with fields:
	%				--- general ---
	%				pi    		optimal solution
	%				objval 		objective value
	%               vltcst    	violation of constraints
	%				time   		time elapsed
	%				--- sinkhorn ---
	%				maxiter maximum number of iteration
	%               
	%
	% Author: Yifei Wang & Feng Zhu
	% Version 1.1 .... 2018/12
	%%-------------------------------------------------------------------------

	tic;
	if nargin<2; opts=[]; end
	if ~isfield(opts, 'epsilon');  opts.epsilon = 1e-6;   end
	if ~isfield(opts, 'maxiter');  opts.maxiter = 1e3;    end
	if ~isfield(opts, 'add_coup'); opts.add_coup = 0;     end
	if ~isfield(opts, 'tqdm');	   opts.tqdm = 0; 		  end

	% copy parameter
	epsilon = opts.epsilon;
	maxiter = opts.maxiter;
	add_coup = opts.add_coup;
	tqdm = opts.tqdm;

	m = model.m;
	n = model.n;
	C = reshape(model.obj,m,n);
	cst = model.cst;
	mu = cst(1:m);
	nu = cst(m+1:m+n);
	logmu = log(mu);
	lognu = log(nu);

	g = zeros(n,1);

	iter = 1;
	while iter <= maxiter
		fhat = max(-C+g',[],2);
		f = epsilon*(logmu-log(sum(exp((-C+g'-fhat)/epsilon),2)))-fhat;
		ghat = max(-C'+f',[],2);
		g = epsilon*(lognu-log(sum(exp((-C'+f'-ghat)/epsilon),2)))-ghat;
	    iter = iter+1;
	    if tqdm && mod(iter,maxiter/10)==0
	    	fprintf(['(',mat2str(iter),'/',mat2str(maxiter),')']);toc;
	    end
	end
	time = toc;

	if add_coup
		fhat = max(-C+g',[],2);
		f = f+min(epsilon*(logmu-log(sum(exp((-C+g'-fhat)/epsilon),2)))-fhat-f,0);
		ghat = max(-C'+f',[],2);
		g = g+min(epsilon*(lognu-log(sum(exp((-C'+f'-ghat)/epsilon),2)))-ghat-g,0);
		fhat = max(-C+g',[],2);

		delta1 = mu-(sum(exp((-C+g'-fhat)/epsilon),2)).*exp((fhat+f)/epsilon);
		delta1 = delta1/norm(delta1,1);
		delta2 = nu-(sum(exp((-C'+f'-ghat)/epsilon),2)).*exp((ghat+g)/epsilon);
		Pi = exp((f-C+g')/epsilon)+delta1*delta2';
	else
		Pi = exp((f-C+g')/epsilon);
	end


	if any(isnan(Pi))
	    error('NaN encountered.')
	end

	out.pi = Pi;
	out.vltcst = norm([sum(Pi, 1)-nu', sum(Pi, 2)'-mu'],1);
	out.objval = sum(sum(C.*Pi));
	out.time = time;


end
