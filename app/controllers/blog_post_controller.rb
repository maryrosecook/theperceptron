class BlogPostController < ApplicationController
  layout 'application', :except => ['ip', 'edit_iphone']
  before_filter :admin_login_required, :except => ['index', 'show', 'edit_iphone', 'ip', 'rss']
  
  MAX_POSTS_PER_PAGE = 10
  
  def index
    @blog = true
    @admin_logged_in = admin_logged_in?
    if request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/(iPhone|iPod)/]
      @iPhone = true
    end
    
    cur_offset = params[:offset].to_i || Util::LIM_NO_OFFSET
    
    # set up paging offset values
    if BlogPost.count_by_publish_state(BlogPost::PUBLISHED) > cur_offset + MAX_POSTS_PER_PAGE
      @new_older_offset = cur_offset + MAX_POSTS_PER_PAGE
    else
      @new_older_offset = nil
    end
    if cur_offset == Util::LIM_NO_OFFSET
      @new_newer_offset = nil
    else
      @new_newer_offset = cur_offset - MAX_POSTS_PER_PAGE
    end
    
    @unpublished_posts = Array.new()
    if logged_in?
      @unpublished_posts = BlogPost.find_by_publish_state(BlogPost::UNPUBLISHED, Util::LIM_NO_OFFSET, Util::LIM_INFINITE)
    end
    
    @published_posts = BlogPost.find_by_publish_state(BlogPost::PUBLISHED, cur_offset, MAX_POSTS_PER_PAGE)
  end
  
  def show
    @blog = true
    @admin_logged_in = admin_logged_in?
    if request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/(iPhone|iPod)/]
      @iPhone = true
    end
    @blog_post = BlogPost.find(params[:id])
    if @blog_post.publishable
      @showing_published = true
    end
  end

  def ip
    @blog_post = BlogPost.new()
  end

  def new
    @blog_post = BlogPost.new()
  end

  def create
    @blog_post = BlogPost.new(params[:blog_post])
    @blog_post.fill_in_blanks()

    if @blog_post.save
      flash[:notice] = 'Post was successfully created.'
      redirect_to :controller => 'blog'
    else
      render :action => 'new'
    end
  end

  def edit
    @blog_post = BlogPost.find(params[:id])
  end

  def edit_iphone
    @blog_post = BlogPost.find(params[:id])
  end

  def update
    @blog_post = BlogPost.find(params[:id])
    if @blog_post.update_attributes(params[:blog_post])
      flash[:notice] = 'Post was successfully updated.'
      redirect_to :action => 'show', :id => @blog_post
    else
      render :action => 'edit'
    end
  end

  def destroy
    post = BlogPost.find(params[:id])
    post.destroy()
    redirect_to :action => 'index'
  end
  
  def rss
    @blog = true
    @blog_posts = BlogPost.recent()
    render :layout => false
  end
end