class Api::V1::PostsController < ApplicationController
  before_action :set_post, only: [ :show, :update, :destroy ]

  # GET /api/v1/posts
  def index
    @posts = Post.all
    render json: @posts
  end

  # GET /api/v1/posts/:id
  def show
    render json: @post
  end

  # POST /api/v1/posts
  def create
    @post = Post.new(post_params)

    if @post.save
      render json: @post, status: :created
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/posts/:id
  def update
    if @post.update(post_params)
      render json: @post
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/posts/:id
  def destroy
    @post.destroy
    head :no_content
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :content, :published)
  end
end
