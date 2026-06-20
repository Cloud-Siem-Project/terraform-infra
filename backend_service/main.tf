module "backend_service" {
  source = "../modules/backend_service"

  project_name     = var.project_name
  environment      = var.environment
  master_py_source = "${path.root}/../../backend/master.py"

  # Workers register/heartbeat via the master's private IP. Allow their SG
  # through to the API port. Cycle is safe — terraform's per-resource graph
  # resolves: worker_sg → master_sg → master_instance → worker_instances.
  trusted_sg_ids = [module.worker_nodes.security_group_id]
}

module "worker_nodes" {
  source = "../modules/worker_nodes"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.backend_service.vpc_id
  master_private_ip = module.backend_service.private_ip
  worker_py_source  = "${path.root}/../../backend/worker.py"
}
