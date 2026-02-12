FROM public.ecr.aws/lambda/python:3.13


RUN pip install uv
COPY pyproject.toml uv.lock ./

RUN uv pip install --system -r <(uv export --format requirements-txt)



COPY models/lr_rul_pipeline.joblib ./Models/
COPY src/lambda_function.py ./

CMD ["lambda_function.lambda_handler"]

