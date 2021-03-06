get '/signin' do
  @title = 'Sign in'
  erb :sign_in
end

get '/signup' do  
  @title = 'Sign up'
  erb :sign_up
end

post '/signin' do
  user = User.find_by(name: params[:name])
  if user && user.authenticate(params[:password])
    session[:user] = user.id
  else 
    session[:error] = 'different password'
    redirect '/signin'
  end
  redirect '/'
end

post '/signup' do
  puts params
  if User.where({name: params[:name]}).count != 0
    session[:error] = 'already sign up your name'
    redirect '/signup'
  end
  if params[:password] != params[:password_confirmation]
    session[:error] = 'different password'
    redirect '/signup'
  end
  @user = User.create(
    name: params[:name],
    password: params[:password],
    password_confirmation: params[:password_confirmation])
  session[:error] = nil
  if @user.persisted?
    session[:user] = @user.id
  end
  redirect '/'
end

get '/signout' do
  session[:user] = nil
  redirect '/'
end