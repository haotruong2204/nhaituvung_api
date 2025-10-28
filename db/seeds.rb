# Clear existing data
Post.destroy_all

# Create sample posts
5.times do |i|
  Post.create!(
    title: "Sample Post #{i + 1}",
    content: "This is the content of post number #{i + 1}",
    published: [ true, false ].sample
  )
end

puts "Created #{Post.count} posts"
