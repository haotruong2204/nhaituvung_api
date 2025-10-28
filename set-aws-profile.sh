#!/bin/bash

echo "=== AWS Profile Check ==="
echo ""

# Set profile
export AWS_PROFILE=nhaituvung

echo "1. Available profiles:"
aws configure list-profiles
echo ""

echo "2. Current AWS_PROFILE: $AWS_PROFILE"
echo ""

echo "3. nhaituvung region:"
aws configure get region --profile nhaituvung
echo ""

echo "4. nhaituvung identity:"
aws sts get-caller-identity --profile nhaituvung
echo ""

echo "5. Using AWS_PROFILE env (no --profile flag):"
aws sts get-caller-identity
echo ""

echo "=== Done ==="
