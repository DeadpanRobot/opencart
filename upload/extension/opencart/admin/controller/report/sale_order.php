<?php
namespace Opencart\Application\Controller\Extension\Opencart\Report;
class SaleOrder extends \Opencart\System\Engine\Controller {
	public function index() {
		$this->load->language('extension/opencart/report/sale_order');

		$this->document->setTitle($this->language->get('heading_title'));

		$this->load->model('setting/setting');

		if (($this->request->server['REQUEST_METHOD'] == 'POST') && $this->validate()) {
			$this->model_setting_setting->editSetting('report_sale_order', $this->request->post);

			$this->session->data['success'] = $this->language->get('text_success');

			$this->response->redirect($this->url->link('marketplace/extension', 'user_token=' . $this->session->data['user_token'] . '&type=report'));
		}

		if (isset($this->error['warning'])) {
			$data['error_warning'] = $this->error['warning'];
		} else {
			$data['error_warning'] = '';
		}

		$data['breadcrumbs'] = [];

		$data['breadcrumbs'][] = [
			'text' => $this->language->get('text_home'),
			'href' => $this->url->link('common/dashboard', 'user_token=' . $this->session->data['user_token'])
		];

		$data['breadcrumbs'][] = [
			'text' => $this->language->get('text_extension'),
			'href' => $this->url->link('marketplace/extension', 'user_token=' . $this->session->data['user_token'] . '&type=report')
		];

		$data['breadcrumbs'][] = [
			'text' => $this->language->get('heading_title'),
			'href' => $this->url->link('extension/opencart/report/sale_order', 'user_token=' . $this->session->data['user_token'])
		];

		$data['action'] = $this->url->link('extension/opencart/report/sale_order', 'user_token=' . $this->session->data['user_token']);

		$data['cancel'] = $this->url->link('marketplace/extension', 'user_token=' . $this->session->data['user_token'] . '&type=report');

		if (isset($this->request->post['report_sale_order_status'])) {
			$data['report_sale_order_status'] = $this->request->post['report_sale_order_status'];
		} else {
			$data['report_sale_order_status'] = $this->config->get('report_sale_order_status');
		}

		if (isset($this->request->post['report_sale_order_sort_order'])) {
			$data['report_sale_order_sort_order'] = $this->request->post['report_sale_order_sort_order'];
		} else {
			$data['report_sale_order_sort_order'] = $this->config->get('report_sale_order_sort_order');
		}

		$data['header'] = $this->load->controller('common/header');
		$data['column_left'] = $this->load->controller('common/column_left');
		$data['footer'] = $this->load->controller('common/footer');

		$this->response->setOutput($this->load->view('extension/opencart/report/sale_order_form', $data));
	}
	
	protected function validate() {
		if (!$this->user->hasPermission('modify', 'extension/report/sale_order')) {
			$this->error['warning'] = $this->language->get('error_permission');
		}

		return !$this->error;
	}
		
	public function report() {
		$this->load->language('extension/opencart/report/sale_order');

		if (isset($this->request->get['filter_date_start'])) {
			$filter_date_start = $this->request->get['filter_date_start'];
		} else {
			$filter_date_start = date('Y-m-d', strtotime(date('Y') . '-' . date('m') . '-01'));
		}

		if (isset($this->request->get['filter_date_end'])) {
			$filter_date_end = $this->request->get['filter_date_end'];
		} else {
			$filter_date_end = date('Y-m-d');
		}

		if (isset($this->request->get['filter_group'])) {
			$filter_group = $this->request->get['filter_group'];
		} else {
			$filter_group = 'week';
		}

		if (isset($this->request->get['filter_order_status_id'])) {
			$filter_order_status_id = $this->request->get['filter_order_status_id'];
		} else {
			$filter_order_status_id = 0;
		}

		if (isset($this->request->get['page'])) {
			$page = $this->request->get['page'];
		} else {
			$page = 1;
		}

		$this->load->model('extension/report/sale');

		$data['orders'] = [];

		$filter_data = [
			'filter_date_start'	     => $filter_date_start,
			'filter_date_end'	     => $filter_date_end,
			'filter_group'           => $filter_group,
			'filter_order_status_id' => $filter_order_status_id,
			'start'                  => ($page - 1) * $this->config->get('config_pagination'),
			'limit'                  => $this->config->get('config_pagination')
		];

		$order_total = $this->model_extension_report_sale->getTotalOrders($filter_data);

		$results = $this->model_extension_report_sale->getOrders($filter_data);

		foreach ($results as $result) {
			$data['orders'][] = [
				'date_start' => date($this->language->get('date_format_short'), strtotime($result['date_start'])),
				'date_end'   => date($this->language->get('date_format_short'), strtotime($result['date_end'])),
				'orders'     => $result['orders'],
				'products'   => $result['products'],
				'tax'        => $this->currency->format($result['tax'], $this->config->get('config_currency')),
				'total'      => $this->currency->format($result['total'], $this->config->get('config_currency'))
			];
		}

		$data['user_token'] = $this->session->data['user_token'];

		$this->load->model('localisation/order_status');

		$data['order_statuses'] = $this->model_localisation_order_status->getOrderStatuses();

		$data['groups'] = [];

		$data['groups'][] = [
			'text'  => $this->language->get('text_year'),
			'value' => 'year',
		];

		$data['groups'][] = [
			'text'  => $this->language->get('text_month'),
			'value' => 'month',
		];

		$data['groups'][] = [
			'text'  => $this->language->get('text_week'),
			'value' => 'week',
		];

		$data['groups'][] = [
			'text'  => $this->language->get('text_day'),
			'value' => 'day',
		];

		$url = '';

		if (isset($this->request->get['filter_date_start'])) {
			$url .= '&filter_date_start=' . $this->request->get['filter_date_start'];
		}

		if (isset($this->request->get['filter_date_end'])) {
			$url .= '&filter_date_end=' . $this->request->get['filter_date_end'];
		}

		if (isset($this->request->get['filter_group'])) {
			$url .= '&filter_group=' . $this->request->get['filter_group'];
		}

		if (isset($this->request->get['filter_order_status_id'])) {
			$url .= '&filter_order_status_id=' . $this->request->get['filter_order_status_id'];
		}

		$data['pagination'] = $this->load->controller('common/pagination', [
			'total' => $order_total,
			'page'  => $page,
			'limit' => $this->config->get('config_pagination'),
			'url'   => $this->url->link('report/report', 'user_token=' . $this->session->data['user_token'] . '&code=sale_order' . $url . '&page={page}')
		]);

		$data['results'] = sprintf($this->language->get('text_pagination'), ($order_total) ? (($page - 1) * $this->config->get('config_pagination')) + 1 : 0, ((($page - 1) * $this->config->get('config_pagination')) > ($order_total - $this->config->get('config_pagination'))) ? $order_total : ((($page - 1) * $this->config->get('config_pagination')) + $this->config->get('config_pagination')), $order_total, ceil($order_total / $this->config->get('config_pagination')));

		$data['filter_date_start'] = $filter_date_start;
		$data['filter_date_end'] = $filter_date_end;
		$data['filter_group'] = $filter_group;
		$data['filter_order_status_id'] = $filter_order_status_id;

		return $this->load->view('extension/opencart/report/sale_order_info', $data);
	}
}