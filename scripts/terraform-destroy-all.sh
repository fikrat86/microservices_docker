#!/bin/bash
# Complete Terraform Destroy Script
# This script destroys all AWS resources created by Terraform

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${TERRAFORM_DIR:-$SCRIPT_DIR/../terraform}"

# Resource names (can be overridden via environment variables)
STATE_BUCKET_PREFIX="${STATE_BUCKET_PREFIX:-forum-microservices-terraform-state}"
LOCK_TABLE_NAME="${LOCK_TABLE_NAME:-forum-microservices-terraform-locks}"

# Default values
ENVIRONMENT="${ENVIRONMENT:-dev}"
AUTO_APPROVE="${AUTO_APPROVE:-false}"
DRY_RUN="${DRY_RUN:-false}"

# Function to print colored messages
print_header() {
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed or not in PATH"
        print_info "Please install Terraform from https://www.terraform.io/downloads"
        exit 1
    fi
    print_success "Terraform is installed: $(terraform version | head -n1)"
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed or not in PATH"
        print_info "Please install AWS CLI from https://aws.amazon.com/cli/"
        exit 1
    fi
    print_success "AWS CLI is installed: $(aws --version)"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured or invalid"
        print_info "Please configure AWS credentials using 'aws configure'"
        exit 1
    fi
    print_success "AWS credentials are valid"
    echo ""
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Destroy all AWS resources created by Terraform

OPTIONS:
    -e, --environment ENV    Environment to destroy (default: dev)
    -a, --auto-approve       Auto-approve destruction without confirmation
    -d, --dry-run           Show what would be destroyed without actually destroying
    -h, --help              Display this help message

EXAMPLES:
    # Dry run to see what would be destroyed
    $0 --dry-run

    # Destroy with confirmation prompt
    $0 --environment dev

    # Destroy without confirmation (use with caution!)
    $0 --environment dev --auto-approve

ENVIRONMENT VARIABLES:
    ENVIRONMENT    Environment to destroy (default: dev)
    AUTO_APPROVE   Set to 'true' to skip confirmation
    DRY_RUN        Set to 'true' for dry run

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -a|--auto-approve)
            AUTO_APPROVE="true"
            shift
            ;;
        -d|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_header "Terraform Destroy - AWS Resources"
    echo ""
    print_info "Environment: $ENVIRONMENT"
    print_info "Terraform Directory: $TERRAFORM_DIR"
    if [ "$DRY_RUN" = "true" ]; then
        print_warning "DRY RUN MODE - No resources will be destroyed"
    fi
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Change to terraform directory
    if [ ! -d "$TERRAFORM_DIR" ]; then
        print_error "Terraform directory not found: $TERRAFORM_DIR"
        exit 1
    fi
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    print_info "Initializing Terraform..."
    if terraform init; then
        print_success "Terraform initialized successfully"
    else
        print_error "Failed to initialize Terraform"
        exit 1
    fi
    echo ""
    
    # Show what will be destroyed
    print_info "Generating destroy plan..."
    if terraform plan -destroy -var="environment=$ENVIRONMENT"; then
        print_success "Destroy plan generated successfully"
    else
        print_error "Failed to generate destroy plan"
        exit 1
    fi
    echo ""
    
    # If dry run, exit here
    if [ "$DRY_RUN" = "true" ]; then
        print_header "Dry Run Complete"
        print_warning "No resources were destroyed. Run without --dry-run to actually destroy resources."
        exit 0
    fi
    
    # Confirmation prompt (unless auto-approve is set)
    if [ "$AUTO_APPROVE" != "true" ]; then
        echo ""
        print_warning "WARNING: This will destroy ALL infrastructure resources!"
        print_warning "This action cannot be undone."
        echo ""
        read -p "Are you sure you want to destroy all resources? (type 'yes' to confirm): " confirmation
        
        if [ "$confirmation" != "yes" ]; then
            print_info "Destruction cancelled by user"
            exit 0
        fi
    fi
    
    # Execute destroy
    echo ""
    print_header "Destroying AWS Resources"
    echo ""
    
    if [ "$AUTO_APPROVE" = "true" ]; then
        print_info "Executing terraform destroy with auto-approve..."
        terraform destroy -var="environment=$ENVIRONMENT" -auto-approve
    else
        print_info "Executing terraform destroy..."
        terraform destroy -var="environment=$ENVIRONMENT"
    fi
    
    if [ $? -eq 0 ]; then
        echo ""
        print_header "Destruction Complete"
        print_success "All Terraform-managed resources have been destroyed"
        echo ""
        print_info "Note: The following may still exist and require manual cleanup:"
        echo "  - S3 bucket: ${STATE_BUCKET_PREFIX}-$ENVIRONMENT"
        echo "  - DynamoDB table: $LOCK_TABLE_NAME"
        echo "  - ECR repositories (if force delete was not enabled)"
        echo "  - CloudWatch log groups"
        echo ""
        print_info "To remove the Terraform state backend, run:"
        echo "  aws s3 rb s3://${STATE_BUCKET_PREFIX}-$ENVIRONMENT --force"
        echo "  aws dynamodb delete-table --table-name $LOCK_TABLE_NAME"
        echo ""
    else
        print_error "Terraform destroy failed"
        exit 1
    fi
}

# Run main function
main
