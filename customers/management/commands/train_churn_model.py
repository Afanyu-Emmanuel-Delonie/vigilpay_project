from django.core.management.base import BaseCommand

from customers.ml_service import train_churn_model_from_datasets


class Command(BaseCommand):
    help = "Train churn model from customers/dataset files and persist artifact."

    def add_arguments(self, parser):
        parser.add_argument(
            "--rows",
            type=int,
            default=5000,
            help="Number of rows to sample for training (default: 5000).",
        )
        parser.add_argument(
            "--seed",
            type=int,
            default=42,
            help="Random seed for sampling/split (default: 42).",
        )
        parser.add_argument(
            "--no-tune",
            action="store_true",
            help="Skip cross-validated hyperparameter search for faster training.",
        )

    def handle(self, *args, **options):
        rows = int(options["rows"])
        seed = int(options["seed"])
        tune = not bool(options["no_tune"])

        result = train_churn_model_from_datasets(min_rows=rows, random_state=seed, tune=tune)
        if not result.get("trained"):
            reason = result.get("reason", "unknown error")
            self.stderr.write(self.style.ERROR(f"Training failed: {reason}"))
            return

        metrics = result.get("metrics", {})
        self.stdout.write(self.style.SUCCESS("Training completed successfully."))
        self.stdout.write(f"Model path: {result.get('path')}")
        self.stdout.write(f"Rows used: {result.get('samples')}")
        if metrics:
            self.stdout.write(
                "Metrics: "
                f"accuracy={metrics.get('accuracy')}%, "
                f"precision={metrics.get('precision')}%, "
                f"recall={metrics.get('recall')}%, "
                f"auc={metrics.get('auc')}%, "
                f"train_accuracy={metrics.get('train_accuracy')}%, "
                f"generalization_gap={metrics.get('generalization_gap')}%"
            )
            if metrics.get("best_params"):
                self.stdout.write(f"Best params: {metrics.get('best_params')}")
