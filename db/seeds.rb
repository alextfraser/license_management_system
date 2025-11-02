# Clear existing data
puts "Clearing existing data..."
LicenseAssignment.destroy_all
Subscription.destroy_all
User.destroy_all
Product.destroy_all
Account.destroy_all

# Create Products
puts "Creating products..."
products = [
  Product.create!(name: "vLex Colombia", description: "Legal research platform for Colombia"),
  Product.create!(name: "vLex Costa Rica", description: "Legal research platform for Costa Rica"),
  Product.create!(name: "vLex España", description: "Legal research platform for Spain"),
  Product.create!(name: "Microsoft Office", description: "Productivity suite with Word, Excel, PowerPoint"),
  Product.create!(name: "Adobe Creative Cloud", description: "Creative tools for designers and developers")
]

# Create Accounts
puts "Creating accounts..."
account1 = Account.create!(name: "Best Law Firm")
account2 = Account.create!(name: "Acme Corp")
account3 = Account.create!(name: "Tech Industries")
account4 = Account.create!(name: "Startup Inc")  # No subscriptions yet

# Create Users with varied counts and diverse names
puts "Creating users..."

# Account 1: 5 users (Best Law Firm)
account1_users = [
  [ "Sarah Johnson", "sarah.johnson@bestlawfirm.com" ],
  [ "Michael Chen", "michael.chen@bestlawfirm.com" ],
  [ "Emma Davis", "emma.davis@bestlawfirm.com" ],
  [ "James Wilson", "james.wilson@bestlawfirm.com" ],
  [ "Lisa Anderson", "lisa.anderson@bestlawfirm.com" ]
].map { |name, email| account1.users.create!(name: name, email: email) }

# Account 2: 3 users (Acme Corp)
account2_users = [
  [ "Robert Taylor", "robert.taylor@acmecorp.com" ],
  [ "Jennifer Martinez", "jennifer.martinez@acmecorp.com" ],
  [ "David Brown", "david.brown@acmecorp.com" ]
].map { |name, email| account2.users.create!(name: name, email: email) }

# Account 3: 7 users (Tech Industries)
account3_users = [
  [ "Amanda White", "amanda.white@techindustries.com" ],
  [ "Chris Garcia", "chris.garcia@techindustries.com" ],
  [ "Maria Rodriguez", "maria.rodriguez@techindustries.com" ],
  [ "Kevin Lee", "kevin.lee@techindustries.com" ],
  [ "Nicole Thomas", "nicole.thomas@techindustries.com" ],
  [ "Ryan Clark", "ryan.clark@techindustries.com" ],
  [ "Jessica Moore", "jessica.moore@techindustries.com" ]
].map { |name, email| account3.users.create!(name: name, email: email) }

# Account 4: 2 users (Startup Inc - no subscriptions)
account4_users = [
  [ "Tom Harris", "tom.harris@startupinc.com" ],
  [ "Emily Parker", "emily.parker@startupinc.com" ]
].map { |name, email| account4.users.create!(name: name, email: email) }

# Create Subscriptions with varied scenarios
puts "Creating subscriptions..."

# Account 1 (Best Law Firm): Some licenses available - matches UI design
account1.subscriptions.create!(
  product: products[0], # vLex Colombia
  number_of_licenses: 10,
  issued_at: 1.month.ago,
  expires_at: 11.months.from_now
)

account1.subscriptions.create!(
  product: products[1], # vLex Costa Rica
  number_of_licenses: 10,
  issued_at: 1.month.ago,
  expires_at: 11.months.from_now
)

account1.subscriptions.create!(
  product: products[2], # vLex España
  number_of_licenses: 10,
  issued_at: 1.month.ago,
  expires_at: 11.months.from_now
)

# Account 2 (Acme Corp): Renewal scenario - expired + renewed subscription
# OLD expired subscription for vLex Colombia
account2.subscriptions.create!(
  product: products[0], # vLex Colombia - EXPIRED (old subscription)
  number_of_licenses: 5,
  issued_at: 2.years.ago,
  expires_at: 1.year.ago  # EXPIRED
)

# NEW active subscription for vLex Colombia (renewal)
account2.subscriptions.create!(
  product: products[0], # vLex Colombia - ACTIVE (renewed)
  number_of_licenses: 3,
  issued_at: 1.month.ago,
  expires_at: 11.months.from_now
)

# Microsoft Office - will be fully used
account2.subscriptions.create!(
  product: products[3], # Microsoft Office
  number_of_licenses: 3,
  issued_at: 2.months.ago,
  expires_at: 10.months.from_now
)

# Account 3 (Tech Industries): Mix of scenarios
account3.subscriptions.create!(
  product: products[3], # Microsoft Office - some available
  number_of_licenses: 10,
  issued_at: 1.month.ago,
  expires_at: 11.months.from_now
)

account3.subscriptions.create!(
  product: products[4], # Adobe Creative Cloud - will be fully used
  number_of_licenses: 7,
  issued_at: 1.month.ago,
  expires_at: 11.months.from_now
)

account3.subscriptions.create!(
  product: products[1], # vLex Costa Rica - expired
  number_of_licenses: 5,
  issued_at: 3.years.ago,
  expires_at: 2.years.ago  # EXPIRED
)

# Account 4 (Startup Inc): NO SUBSCRIPTIONS - for testing empty state

# Create license assignments
puts "Creating license assignments..."

# Account 1: 5/10 used for Colombia and Costa Rica, 0/10 for España
account1_users.each do |user|
  LicenseAssignment.create!(account: account1, user: user, product: products[0]) # vLex Colombia
  LicenseAssignment.create!(account: account1, user: user, product: products[1]) # vLex Costa Rica
end

# Account 2: All users assigned to vLex Colombia (renewed subscription) and Microsoft Office
account2_users.each do |user|
  LicenseAssignment.create!(account: account2, user: user, product: products[0]) # vLex Colombia (3/3 - fully used)
  LicenseAssignment.create!(account: account2, user: user, product: products[3]) # Microsoft Office (3/3 - fully used)
end

# Account 3: Partially used (4/10) for Office, Fully used (7/7) for Adobe
account3_users[0..3].each do |user|
  LicenseAssignment.create!(account: account3, user: user, product: products[3]) # Microsoft Office
end

account3_users.each do |user|
  LicenseAssignment.create!(account: account3, user: user, product: products[4]) # Adobe Creative Cloud
end

puts "\nSeed data created successfully!"
puts "----------------------------------------"
puts "Accounts: #{Account.count}"
puts "Products: #{Product.count}"
puts "Users: #{User.count}"
puts "Subscriptions: #{Subscription.count}"
puts "License Assignments: #{LicenseAssignment.count}"
puts "----------------------------------------"
puts "\n📊 Testing Scenarios:"
puts "  1️⃣  Best Law Firm    - Some licenses available (5/10 used)"
puts "  2️⃣  Acme Corp        - RENEWAL: Expired + renewed vLex Colombia (3/3 used on new)"
puts "  3️⃣  Tech Industries  - Mixed: partial (4/10) and full (7/7) usage + expired"
puts "  4️⃣  Startup Inc      - No subscriptions yet (empty state)"
puts "----------------------------------------"
puts "\nYou can now:"
puts "1. Visit http://localhost:3000"
puts "2. View accounts and manage licenses"
puts "3. Test the bulk assignment feature with realistic data"
