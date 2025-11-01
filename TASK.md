
Take-Home Test: Simple License Management System 
Objective 
Create a Ruby on Rails application that implements a simple license management system, which allows the assignment of licenses to users on the account based on the subscription. 
The goal of this project is to build a License Management System for an organisation that enables administrators to manage accounts, users, products, subscriptions, and licenses. This system will allow administrators to assign licenses to users based on subscriptions to products, track the available and used licenses, and ensure proper validation of license assignments. 
Requirements 
1. Models 
● Account Model: 
○ name (string): Name of the account 
● User Model: 
○ name (string): Name of the user. 
○ email (string): Email address of the user (unique). 
○ account_id (integer): Foreign key to the Account model (relationship). 
● Product Model: 
○ name (string): Name of the product. 
○ description (text): Description of the product. 
● Subscription Model: 
○ account_id (integer): Foreign key to the Account model (relationship). 
○ product_id (integer): Foreign key to the Product model (relationship). 
○ number_of_licenses (integer): The number of licenses to this product 
○ issued_at (datetime): Timestamp for when the license was issued. 
○ expires_at (datetime): Timestamp for when the license expires. 
● LicenseAssignment Model: 
○ account_id (integer): Foreign key to the Account model (relationship). 
○ user_id (integer): Foreign key to the User model (relationship). 
○ product_id (integer): Foreign key to the Product model (relationship).

User Stories 
1. Adding an Account 
As an administrator, 
I want to create an account, 
So that I can manage users, products, and subscriptions associated with that account. Acceptance Criteria: 
● The system allows the creation of a new account with a name. 
● After creating the account, the administrator is redirected to the account details page. ● The account should be stored with a unique id. 
Design 
Simple Functional Design with a list of accounts and the ability to add a new account. 2. Adding a Product 
As an administrator, 
I want to add a product to the system, 
So that it can be assigned to an account and subscribed to by users. 
Acceptance Criteria: 
● The system allows the creation of a product with name and description. ● After creating the product, the administrator is redirected to the product details page. ● The product should be stored with a unique id. 
Design 
Simple functional design with a list of products and the ability to add a new product. 
3. Adding a User to an Account 
As an administrator, 
I want to add a user to an account, 
So that the user can be assigned licenses for products within that account. Acceptance Criteria: 
● The system allows adding a user with a name, email, and an associated account_id. ● If the email is already in use, the system should show an error message.

● After creating the user, the administrator is redirected to the account’s user list. Design 
Simple functional design with a list of users on the account and the ability to add a new user. 4. Adding a Subscription for an Account for a Particular Product 
As an administrator, 
I want to add a subscription for a product to an account, 
So that the account can have a specific number of licenses for that product. Acceptance Criteria: 
● The system allows the creation of a subscription with account_id, product_id, number_of_license, issued_at, and expires_at. 
● The system validates the number of licenses to be positive. 


● After creating the subscription, the administrator is redirected to the account’s subscription list. Design 
Simple functional design with a list of subscriptions and the ability to add a new subscription. There should be a list of the available products for the users to pick from. 
5. Assigning a License for a Product to a User on the Account 
As an administrator, 
I want to assign a license for a product to a user in the account. 
So that the user can access the product’s features based on the license. 
Acceptance Criteria: 
● The system allows the assignment of a license to a user 
● Multiple licenses can be assigned to multiple users with one operation. 
● The system ensures that the number of licenses available for the product is checked and only assigns a license if there are available licenses. 
● If the user already has an active license for the same product, the system should prevent assigning a new license being assigned. 
● The administrator can view the list of licenses assigned to users in the account.


Key Design Elements 
1. At the top is the name of the account for which we are assigning licenses to users 2. The red bar is where validation messages will be displayed when required. 
3. The left list has a list of the products and the number of licenses available/used 
4. On the right is the list of users for this account 
5. The buttons allow you to assign and unassign the licenses 
6. Multiple licenses can be assigned to multiple users with one operation.
