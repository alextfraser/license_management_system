require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = products(:one)
  end

  test "should get index" do
    get products_url
    assert_response :success
  end

  test "should get show" do
    get product_url(@product)
    assert_response :success
  end

  test "should get new" do
    get new_product_url
    assert_response :success
  end

  test "should create product" do
    assert_difference("Product.count") do
      post products_url, params: { product: { name: "New Product", description: "Test" } }
    end

    assert_redirected_to product_url(Product.last)
  end

  test "should not create product without name" do
    assert_no_difference("Product.count") do
      post products_url, params: { product: { name: "", description: "Test" } }
    end

    assert_response :unprocessable_entity
  end
end
