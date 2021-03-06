require 'rails_helper'

RSpec.feature 'The default cart check out' do
  scenario 'allows to fill all the needed informations in one step' do
    create(:shipping_method, name: 'Fake shipping carrier', identifier: 'fake-shipping-calculator')
    create(:payment_method, name: 'Fake payment gateway', identifier: 'fake-payment-gateway')
    cart = create_filled_cart

    visit checkout_path(cart_key: cart.identifier)

    fill_in Customer.human_attribute_name(:email), with: 'test@example.com'

    within(:css, '[data-address-form="shipping"]') do
      select 'M.', from: Address.human_attribute_name(:civility)
      fill_in Address.human_attribute_name(:first_name), with: 'Jean'
      fill_in Address.human_attribute_name(:last_name), with: 'Val'
      fill_in Address.human_attribute_name(:address), with: '1 rue de la rue'
      fill_in Address.human_attribute_name(:zip), with: '75001'
      fill_in Address.human_attribute_name(:city), with: 'Paris'
      select 'France', from: Address.human_attribute_name(:country)
    end

    # Choose the shipping method
    choose 'Fake shipping carrier'

    # Choose the payment method
    choose 'Fake payment gateway'

    # Accept terms
    check 'terms-checkbox'

    click_on t('stall.checkout.informations.validate')

    expect(page).to have_content t('stall.checkout.payment.title')

    cart.reload

    expect(cart.customer.email).to eq('test@example.com')

    expect(cart.shipping_address.address).to eq('1 rue de la rue')
    expect(cart.billing_address).to eq(cart.shipping_address)

    expect(cart.shipment.shipping_method.name).to eq('Fake shipping carrier')
    expect(cart.shipment.price.to_i).not_to eq(0)

    expect(cart.payment.payment_method.name).to eq('Fake payment gateway')
  end

  scenario 'shows the payment form to access target gateway' do
    payment_method = create(:payment_method, name: 'Fake payment gateway', identifier: 'fake-payment-gateway')
    cart = create_filled_cart
    cart.state = :payment
    cart.build_payment(payment_method: payment_method)
    cart.save!

    visit checkout_step_path(cart.wizard.route_key, cart)

    expect(page).to have_content('Pay')
  end

  scenario 'displays back the payment button form if the payment was aborted' do
    payment_method = create_payment_method
    cart = create_filled_cart
    cart.state = :payment
    cart.build_payment(payment_method: payment_method)
    cart.save!

    visit process_checkout_step_path(cart.wizard.route_key, cart)

    expect(page).to have_content('Pay')
  end

  scenario 'redirects to a thanks screen if the payment succeeded' do
    payment_method = create_payment_method
    cart = create_filled_cart
    cart.state = :payment
    cart.build_payment(payment_method: payment_method)
    cart.save!

    visit process_checkout_step_path(cart.wizard.route_key, cart, succeeded: true)

    expect(cart.reload.state).to eq(:payment_return)
    expect(page).to have_content(t('stall.checkout.payment_return.title'))
  end

  def create_filled_cart
    book = create(:book, title: 'Alice in wonderland')

    visit books_path

    within(:css, "[data-book-id='#{ book.id }']") do
      click_on t('stall.line_items.form.add_to_cart')
    end

    token = find(:xpath, '//div[@data-cart-token]')['data-cart-token']
    Cart.find_by_token!(token)
  end

  def create_payment_method
    create(:payment_method, name: 'Fake payment gateway', identifier: 'fake-payment-gateway')
  end
end
