<style>

.table-klarna {
    width: 100%;
}

.table-klarna tr {
    border-bottom: 1px solid #ddd;
}

.table-klarna td {
    padding: 10px;
}

</style>

{% if shipping_required %}
<div id="klarna-shipping-method">
  <h3>{{ text_choose_shipping_method }}</h3>
  {% if shipping_methods %}
  <p>{{ text_shipping_method }}</p>
 {% for shipping_method in shipping_methods %}
  <p><strong>{{ shipping_method.title }}</strong></p>
  {% if !$shipping_method.error %}
  {% for quote in shipping_method.quote %}
  <div class="radio">
	<label>
	  {% if quote['code'] == $code || !$code %}
	  <?php $code = $quote['code']; ?>
	  <input type="radio" name="shipping_method" value="{{ quote.code }}" checked="checked" />
	  {% else %}
	  <input type="radio" name="shipping_method" value="{{ quote.code }}" />
	  <?php } ?>
	  {{ quote.title }} - {{ quote.text }}</label>
  </div>
  <?php } ?>
  {% else %}
  <div class="alert alert-danger">{{ shipping_method.error }}</div>
  <?php } ?>
  <?php } ?>
  <input type="hidden" name="comment" value="">
  <?php } ?>
</div>
<?php } ?>
<div class="panel panel-primary">
    <div class="panel-heading">
        <h3 class="panel-title">Order Summary</h3>
    </div>
    {% if products || $vouchers %}
        <div style="overflow: auto;">
        	<table class="table-klarna">
        	 {% for product in products %}
        	  <tr>
        		<td class="text-left"><a href="{{ product.href }}">{{ product.name }}</a>
        		  {% if product.option %}
        		  {% for option in product.option %}
        		  <br />
        		  - <small>{{ option.name }} {{ option.value }}</small>
        		  <?php } ?>
        		  <?php } ?>
        		  {% if product.recurring %}
        		  <br />
        		  - <small>{{ text_recurring }} {{ product.recurring }}</small>
        		  <?php } ?></td>
        		<td class="text-right">x {{ product.quantity }}</td>
        		<td class="text-right">{{ product.total }}</td>
        		<td class="text-center"><button type="button" onclick="kc.cartRemove('{{ product.cart_id }}');" title="{{ button_remove }}" class="btn-link"><i class="fa fa-times"></i></button></td>
        	  </tr>
        	  <?php } ?>
        	 {% for voucher in vouchers %}
        	  <tr>
        		<td class="text-left">{{ voucher.description }}</td>
        		<td class="text-right">x&nbsp;1</td>
        		<td class="text-right">{{ voucher.amount }}</td>
        		<td class="text-center"><button type="button" onclick="kc.voucherRemove('{{ voucher.key }}');" title="{{ button_remove }}" class="btn-link"><i class="fa fa-times"></i></button></td>
        	  </tr>
        	  <?php } ?>
        	</table>
        </div>
		<div>
		  <table class="table-klarna">
			% for total in totals %}
			<tr>
			  <td class="text-right"><strong>{{ total.title }}</strong></td>
			  <td class="text-right">{{ total.text }}</td>
			</tr>
			<?php } ?>
		  </table>
		</div>
	  {% else %}
		<p class="text-center">{{ text_empty }}</p>
	  <?php } ?>
</div>

<script type="text/javascript"><!--
$('#klarna-shipping-method input[type=\'radio\'], #confirm-shipping input[type=\'radio\']').change(function() {
	window._klarnaCheckout(function(api) {
		addSidebarOverlay();
		api.suspend();
	});


    $.ajax({
        url: 'index.php?route=checkout/shipping_method/save',
        type: 'post',
        data: $('#klarna-shipping-method input[type=\'radio\']:checked, #klarna-shipping-method input[type=\'hidden\']'),
        dataType: 'json',
        success: function(json) {
            if (json['redirect']) {
                location = json['redirect'];
            } else if (json['error']) {
                console.log(json['error']);
            } else {
				$.post('index.php?route=extension/payment/klarna_checkout/main', {response: 'json'}, function() {
					$('.klarna-checkout-sidebar').load('index.php?route=extension/payment/klarna_checkout/sidebar', function() {
						window._klarnaCheckout(function(api) {
							api.resume();
							removeSidebarOverlay();
						});
					});

					$.get('index.php?route=extension/payment/klarna_checkout/cartTotal', function(total) {
						setTimeout(function() {
							$('#cart > button').html('<span id="cart-total"><i class="fa fa-shopping-cart"></i> ' + total + '</span>');
						}, 100);

						$('#cart > ul').load('index.php?route=common/cart/info ul li');
					});
				});
            }
        },
        error: function(xhr, ajaxOptions, thrownError) {
            alert(thrownError + "\r\n" + xhr.statusText + "\r\n" + xhr.responseText);
        }
    });
});

var kc = {
	'cartRemove': function(key) {
		window._klarnaCheckout(function(api) {
			addSidebarOverlay();
			api.suspend();
		});

		$.ajax({
			url: 'index.php?route=checkout/cart/remove',
			type: 'post',
			data: 'key=' + key,
			dataType: 'json',
			complete: function() {
				window._klarnaCheckout(function(api) {
					api.resume();
					removeSidebarOverlay();
				});
			},
			success: function(json) {
				$.post('index.php?route=extension/payment/klarna_checkout/main', {response: 'json'}, function(data) {
					if (data['redirect']) {
						location = data['redirect'];
					} else {
						$('.klarna-checkout-sidebar').load('index.php?route=extension/payment/klarna_checkout/sidebar', function() {
							window._klarnaCheckout(function(api) {
								api.resume();
								removeSidebarOverlay();
							});
						});

						// Need to set timeout otherwise it wont update the total
						setTimeout(function() {
							$('#cart > button').html('<span id="cart-total"><i class="fa fa-shopping-cart"></i> ' + json['total'] + '</span>');
						}, 100);

						$('#cart > ul').load('index.php?route=common/cart/info ul li');
					}
				});
			},
	        error: function(xhr, ajaxOptions, thrownError) {
	            alert(thrownError + "\r\n" + xhr.statusText + "\r\n" + xhr.responseText);
	        }
		});
	},
	'voucherRemove': function(key) {
		window._klarnaCheckout(function(api) {
			addSidebarOverlay();
			api.suspend();
		});

		$.ajax({
			url: 'index.php?route=checkout/cart/remove',
			type: 'post',
			data: 'key=' + key,
			dataType: 'json',
			complete: function() {
				window._klarnaCheckout(function(api) {
					api.resume();
					removeSidebarOverlay();
				});
			},
			success: function(json) {
				$.post('index.php?route=extension/payment/klarna_checkout/main', {response: 'json'}, function() {
					if (data['redirect']) {
						location = data['redirect'];
					} else {
						$('.klarna-checkout-sidebar').load('index.php?route=extension/payment/klarna_checkout/sidebar', function() {
							window._klarnaCheckout(function(api) {
								api.resume();
								removeSidebarOverlay();
							});
						});

						// Need to set timeout otherwise it wont update the total
						setTimeout(function() {
							$('#cart > button').html('<span id="cart-total"><i class="fa fa-shopping-cart"></i> ' + json['total'] + '</span>');
						}, 100);

						$('#cart > ul').load('index.php?route=common/cart/info ul li');
					}
				});
			},
	        error: function(xhr, ajaxOptions, thrownError) {
	            alert(thrownError + "\r\n" + xhr.statusText + "\r\n" + xhr.responseText);
	        }
		});
	}
};
//--></script>
